---
title: "把 Git 包成互動式 CLI：11 支 fzf 腳本的設計筆記"
date: 2026-08-31T11:42:11+08:00
draft: false
tags: [git, fzf, bash, cli, developer-tools, worktree, rebase]
categories: [工程筆記]
description: "用 fzf 把 git 每天會打、但每次都要想一下的那幾條指令包成互動式腳本，逐支說明各自解決什麼問題。"
---

## 起因

[上一篇](../git-useful-commands/)整理的那幾條指令，參數本身都不難記。麻煩的是那種**要先查才能打**的情境。

想 checkout 一個還沒 checkout 過的遠端分支，得先 `git branch -r`，用眼睛掃一遍，再手動打分支名。想把某段 commit 搬到別條分支，`git rebase --onto <new-base> <old-base> <until>` 三個參數各是什麼，我每次都要想。想拿某個 commit 的 SHA，`git log --oneline` 之後反白複製。

這些操作花時間的部分是**選**，不是執行。fzf 剛好就是拿來解決選的問題。

於是有了 11 支腳本，命名一律是 `git` 加兩個字母，取自指令本身的大寫字母。

完整腳本放在 [Gist](https://gist.github.com/litsungyi/6fd90303bf3fd5ef84d2f50bab96b4b5)。Gist 是扁平結構，使用時把 `git_utils.sh`、`commit-msg`、`generate_commit_message.py` 放進腳本旁的 `helpers/` 目錄，其餘腳本放在 `helpers/` 的上一層。

AI commit message 的部分要注意：

- `commit-msg`（`gitst` 用）依 `GITST_COMMIT_MSG` 選後端：`ollama`（預設，需要名為 `ollama` 的 docker 容器，可用 `OLLAMA_CONTAINER` 改）、`claude`（本機 CLI）、`jev`（需要 `TYPESAFE_API_KEY`，只做檢查）。
- `generate_commit_message.py`（`gitsh` 用）需要 `pip install requests`，並假設本機 `localhost:11434` 有 ollama 與 `gpt-oss`、`gpt-oss-safeguard` 兩個模型。
- `claude` 和 `jev` 會把 staged diff 送到外部服務，機密 repo 請用本機的 `ollama`。
- 安全檢查是請 LLM 判斷有沒有 secret 或 prompt injection，不能保證擋得住，不要當成唯一防線。

## 共同骨架

每支腳本第一行做的事都一樣：source 同一個 `helpers/git_utils.sh`。裡面沒什麼特別的，就是色彩輸出跟前置檢查：

```bash
function hl()   { printf '\033[1;33m%s\033[0m' "$1"; }
function info() { printf '[\033[1;36mINFO\033[0m] %s\n' "$1"; }
function check_git() {
  git rev-parse --is-inside-work-tree > /dev/null 2>&1 || { err "Not a git repository."; exit 1; }
}
```

比較值得提的是 `get_local_branches`。用 `--format` 把四個欄位塞在同一行：

```bash
local format="%(if)%(upstream)%(then)%(refname:short) [%(objectname:short)] -> %(upstream:short)%(else)%(refname:short) [%(objectname:short)] <no upstream>%(end) %(contents:subject)"
git branch -l --format="${format}"
```

這樣在 fzf 清單裡一眼看得到分支名、short SHA、追蹤的 upstream、最後一筆 commit 標題，而 `awk '{print $1}'` 還是能乾淨取回分支名。

fzf 的參數則固定那幾個：`--preview`、`--preview-window=right:60%`、`--header`（把快捷鍵印在畫面上，省得記）、`--bind="esc:abort"`。

## 導覽類

### `gitsw` — SWitch

切本地分支。列出 `git branch`，選一個，`git switch` 過去。preview 是那條分支最近 100 筆 log。

支援帶參數：`gitsw feat` 會直接把 `feat` 當成 fzf 的初始 query，通常打兩三個字就只剩一個候選了。已經在那條分支上會直接告訴你，不會白跑一次 switch。

### `gitco` — CheckOut

`gitsw` 的遠端版本。列的是 `git branch --remote`，選完自動建立追蹤分支再切過去：

```bash
git branch --track "${branch}" "${remote_branch}" && git switch "${branch}"
```

本地分支名是把 `origin/` 這類前綴 `sed` 掉得來的。如果本地已經有同名分支，`git branch --track` 會失敗，此時錯誤訊息會直接叫你改用 `gitsw`——這兩支的分工就是「本地有沒有」。

### `gitbr` — BRanch

查分支資訊，順手把 short SHA 丟進剪貼簿。三個 flag 決定列什麼：

```
gitbr      # 不選，直接回報目前分支
gitbr -l   # 本地分支
gitbr -r   # 遠端分支
gitbr -lr  # 兩邊一起列
gitbr -t   # tag
```

輸出會告訴你這條分支的 SHA、以及有沒有在追蹤 upstream。SHA 不印出來要你複製，直接進剪貼簿。

### `gitl1` — Log 1 line

挑 commit，SHA 進剪貼簿。preview 是 `git show`，所以是邊看 diff 邊挑。

重點在兩個 range 模式：

- `gitl1 -c`（**c**ompare）：先選一條本地分支，然後看 `<branch>..HEAD`——「我這條比它多了什麼」。選分支那步按 ESC 會 fallback 回目前分支。
- `gitl1 -b`：選一條分支（本地遠端都列）直接看它的 log。想比較兩條的話，先用 `tab` 標第一條，再對第二條按 Enter，就會看 `<A>...<B>`。

兩個點和三個點的差別平常很難記住：

- `A..B`：在 B 裡、但不在 A 裡的 commit。有方向性，只看 B 比 A 多的。
- `A...B`（三個點）：只在 A 或只在 B 的 commit，也就是兩條分家之後**各自**多出來的，排除共同祖先。沒有方向性，A、B 互換結果一樣。

包成 flag 之後就不用記了。

### `gitdf` — DiFf

看 diff。三種模式：

- 預設：列出工作目錄的變更檔案（對 HEAD），選一個就把完整 diff 印到終端機，右邊同時有 preview。
- `gitdf -c`：只看 staged 的變更，等於 `git diff --cached`。沒有任何 staged 內容就直接告訴你。
- `gitdf -b`：先選 BASE、再選 TARGET（本地遠端都列），看 `git diff BASE TARGET`，也就是「BASE 要怎麼變成 TARGET」，`-` 是 BASE、`+` 是 TARGET。TARGET 那步按 ESC 則是 BASE 對工作目錄。這模式下檔案清單來自 `git diff --name-status`。`-b` 和 `-c` 不能合用。

清單裡有兩個切換鍵，狀態顯示在 prompt：`C-w` 切換是否忽略空白變更（`--ignore-all-space`），`C-t` 切換是否列出 untracked 檔案（只有預設模式有）。

它是唯一一支跑 `while true` 迴圈的：印完一個檔案的 diff 之後回到清單，讓你連續看好幾個檔案，按 ESC 才離開。

### `gitrl` — RefLog

`git reflog -n 100` 列出最近 100 筆 HEAD 移動紀錄，preview 是 `git show`，選一筆就 `git checkout` 過去。reset 或 rebase 搞砸、想回到之前某個狀態時，比自己翻 reflog 再抄 SHA 快。

checkout 的是 commit，所以會進入 detached HEAD。要保留的話，接著自己建分支。

## 改寫類

### `gitrb` — ReBase

這組裡我最常用的一支。連開三次 fzf 收 ONTO / FROM / TO，然後自己算 merge-base：

```bash
git rebase --onto "$ONTO_BRANCH" "$(git merge-base "$FROM_BRANCH" "$TO_BRANCH")" "$TO_BRANCH"
```

`rebase --onto` 的第二個參數是「舊的 base」，但人腦知道的其實是「這兩條從哪分家」。把 merge-base 這步自動化之後，這指令就從要想三十秒變成選三次。

三個參數都可以先帶進去當 fzf 的初始 query，TO 沒給的話預設是目前分支。FROM 和 TO 選到同一條會直接擋下來。

### `gitst` — STatus

走完整的 status → stage → commit 流程，是這組裡最長的一支。

第一階段是檔案清單。stage / unstage 用 `execute-silent` 加 `reload` **就地更新清單**，不用離開 fzf：

```bash
--bind="ctrl-a:execute-silent(git add -- {2})+reload(git status -u -s -z --no-renames | awk ...)"
```

`Ctrl-A` stage、`Ctrl-R` unstage，選好之後按 Enter 進第二階段：列出最近 100 個 commit，這裡的按鍵決定怎麼 commit：

| 按鍵 | 行為 |
| --- | --- |
| `Ctrl-F` | **F**ixup：對游標所在的 commit 做 `git commit --fixup` |
| `Ctrl-E` | 自己寫 message，直接開編輯器 `git commit` |
| `Enter` | 用 AI 產生 commit message，產出 5 組候選讓你挑 |
| `ESC` | 離開，不 commit |

腳本帶 `-s` 的話，fixup 完接著 `git rebase -i --autosquash "$commit~1"` 一次歸位（`--fixup` 和 `--autosquash` 的細節在[上一篇](../git-useful-commands/)）。base 要用目標的 parent，不然目標 commit 不會出現在 todo 清單裡。

按 Enter 的話，就把 `git diff --cached` 丟給 AI（用環境變數 `GITST_COMMIT_MSG` 選產生器：`ollama` 是預設，`claude` 走本機 CLI，`jev` 只做安全檢查、不產 message）產 5 組 commit message，再用 `--expect` 分流：

```bash
--expect=ctrl-e,ctrl-c
# ctrl-c → git commit（自己寫）
# ctrl-e → git commit -e -F "$file"（改一下再送）
# enter  → git commit -F "$file"
```

每個候選 message 各寫成一個暫存檔。fzf 沒辦法在清單裡渲染多行項目，所以清單只顯示第一行標題，preview 和實際 commit 讀的是完整內容。

產生 message 前會先檢查 staged diff 有沒有不安全的內容（例如 secret）。被擋下時可以確認後跳過檢查重新產生，並用 `--no-verify` commit。

## 暫存與並行

### `gitsh` — staSH

stash / commit / unstash 三種模式。開頭先選模式，沒有任何 stash 時選單裡就不會出現 `unstash`。

- **stash**：可以多選檔案（`tab`），選完問一句 message，然後 `git stash push -- <files>`。
- **commit**：對已 stage 的變更用 AI 產生 commit message 候選，挑一個 commit，`C-e` 可以先編輯再送。產生前會先擋下有衝突的狀態，diff 或產出的 message 沒通過安全檢查也會中止。
- **unstash**：列出所有 stash，preview 是 `git stash show -p`，apply 完再問要不要 drop。

preview 用了 `diff_or_stash`：先掃過所有 stash，如果這個檔案被某個 stash 收走了就顯示那個 stash 內的 diff，否則 fallback 回 `git diff HEAD`。

### `gitwt` — WorkTree

管 worktree。fzf 列出所有 worktree，preview 是該 worktree 的 `git log --graph`。按鍵：

| 按鍵 | 行為 |
| --- | --- |
| `Enter` | 進入選中的 worktree |
| `C-c` | 新增：輸入分支名，分支不存在就用 `-b` 建立，建完直接進入 |
| `C-s` | 把一個既有的本地或遠端分支 checkout 成 worktree（只建立，不進入） |
| `C-d` | 刪除選中的 worktree（`git worktree remove`） |
| `C-r` | 設定新增 worktree 的存放路徑 |
| `C-e` | 用 `$EDITOR` 直接編輯設定檔 |
| `ESC` | 離開 |

C-c、C-d、C-r 做完都會回到清單，失敗的原因會顯示在下一輪清單的 header。

**worktree 路徑。** 預設放 `<root>/.worktree/{branch}`。要改的話用 `C-r` 輸入新路徑（絕對或相對皆可），會依 repo 寫進 `~/.local/share/scripts.json`：

```json
{
  "gitwt": {
    "roots": [
      { "/home/me/src/blog": "/home/me/ws/blog-{branch}" },
      { "/home/me/src/*": "/home/me/ws/*/{branch}" }
    ]
  }
}
```

- `{branch}` 換成分支名，`{repo}` 換成 repo 名。路徑沒帶 `{branch}` 的話，同時只能有一個 worktree 用它。
- key 是主 worktree 的路徑，可以用 `*` 當萬用字元，value 裡的 `*` 會換成 key 對應位置比到的文字。
- `roots` 是陣列，依序比對，**第一個符合的生效**。`C-e` 可以直接編輯這個檔案。

**進入 worktree。** 子行程沒辦法 `cd` 父 shell，所以腳本改成把路徑寫到 fd 3，由 shell 裡的一個 function 接手 `cd`：

```bash
# ~/.zshrc
gitwt() { local d; d="$(command gitwt "$@" 3>&1 1>&2)"; [ -n "$d" ] && cd "$d"; }
```

fzf 的 UI 走 stderr，所以 `1>&2` 把 stdout 轉去 stderr 保持畫面正常，`3>&1` 則把 fd 3 的內容接回來存進 `d`。這樣「進入」就是在**目前這個 shell** 裡 `cd`，不會多開一層，也不用 `exit` 離開。沒載入這個 function 時，腳本只會印出 `cd <path>` 的提示。

### `gitsm` — SubModule

多選 submodule（`tab`），按鍵：

| 按鍵 | 行為 |
| --- | --- |
| `Enter` | 對選中的跑 `sync` 加 `update --init --recursive`，還沒 init 的一併 init |
| `C-a` | 新增：問 repository URL 和路徑（預設取 URL 的 repo 名），`git submodule add` |
| `C-r` | 移除選中的，y/N 確認後依序 `deinit -f`、`git rm -f`，並清掉 `.git/modules` 裡的殘留 |
| `ESC` | 離開 |

preview 會顯示該 submodule 的 log，還沒 init 的就印 `not initialized`。

## 參考資料

- [Git Shell — 完整腳本 Gist](https://gist.github.com/litsungyi/6fd90303bf3fd5ef84d2f50bab96b4b5)
- [junegunn/fzf — README](https://github.com/junegunn/fzf)
- [fzf — ADVANCED.md](https://github.com/junegunn/fzf/blob/master/ADVANCED.md)
- [fzf: Reference](https://junegunn.github.io/fzf/reference/)
- [fzf Wiki — Examples](https://github.com/junegunn/fzf/wiki/examples)
- [git-status(1) Manual Page](https://git-scm.com/docs/git-status)
- [git-rebase(1) Manual Page](https://git-scm.com/docs/git-rebase)
- [git-merge-base(1) Manual Page](https://git-scm.com/docs/git-merge-base)
- [git-worktree(1) Manual Page](https://git-scm.com/docs/git-worktree)
- [How to effectively use git rebase --onto? — Martin Belev](https://belev.dev/how-to-effectively-use-git-rebase-onto/)
- [A gentle introduction to Git worktrees — Human Who Codes](https://humanwhocodes.com/blog/2026/07/introduction-git-worktrees/)
