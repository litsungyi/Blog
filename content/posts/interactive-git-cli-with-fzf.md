---
title: "把 Git 包成互動式 CLI：10 支 fzf 腳本的設計筆記"
date: 2026-08-31T11:42:11+08:00
draft: false
tags: [git, fzf, bash, cli, developer-tools, worktree, rebase]
categories: [工程筆記]
description: "用 fzf 把 git 每天會打、但每次都要想一下的那幾條指令包成互動式腳本，逐支說明各自解決什麼問題，並記錄過程中踩到的 quoting、exit code 與 subshell 坑。"
---

## 起因

[上一篇](../git-useful-commands/)整理的那幾條指令，參數本身都不難記。麻煩的是那種**要先查才能打**的情境。

想 checkout 一個還沒 checkout 過的遠端分支，得先 `git branch -r`，用眼睛掃一遍，再手動打分支名。想把某段 commit 搬到別條分支，`git rebase --onto <new-base> <old-base> <until>` 三個參數各是什麼，我每次都要想。想拿某個 commit 的 SHA，`git log --oneline` 之後反白複製。

這些操作花時間的部分是**選**，不是執行。fzf 剛好就是拿來解決選的問題。

於是有了 10 支腳本，命名一律是 `git` 加兩個字母，取自指令本身的大寫字母。

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

切本地分支。列出 `git branch`，選一個，`git switch` 過去。preview 是那條分支最近 10 筆 log。

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

輸出會告訴你這條分支的 SHA、以及有沒有在追蹤 upstream。SHA 不印出來要你複製，直接進剪貼簿——反正九成情況都是要貼到下一條指令去。

### `gitl1` — Log 1 line

挑 commit，SHA 進剪貼簿。preview 是 `git show`，所以是邊看 diff 邊挑。

重點在兩個 range 模式：

- `gitl1 -h`：先選一條分支，然後看 `<branch>..HEAD`——「我這條比它多了什麼」。
- `gitl1 -b`：選 FROM 和 TO 兩條分支，看 `<A>...<B>`（三個點）——「這兩條分家之後各自有什麼」。

兩個點和三個點的差別平常很難記住，包成 flag 之後就不用記了。選分支那步按 ESC 會 fallback 回目前分支。

### `gitdf` — DiFf

看 diff。預設列出工作目錄的變更檔案，選一個就把完整 diff 印到終端機。

`gitdf -b` 則是先選一條分支（本地遠端都列），改成跟那條分支比。這模式下檔案清單來自 `git diff --name-status <branch>`。

它是唯一一支跑 `while true` 迴圈的：印完一個檔案的 diff 之後回到清單，讓你連續看好幾個檔案，按 ESC 才離開。

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

按 Enter 進第二階段：先讓你挑一個既有 commit 做 `git commit --fixup`，按 ESC 就跳過走一般 commit。腳本帶 `-s` 的話，fixup 完接著 `git rebase -i --autosquash "$commit"` 一次歸位（`--fixup` 和 `--autosquash` 的細節在[上一篇](../git-useful-commands/)）。

不 fixup 的話，就把 `git diff --cached` 丟給 `claude -p` 產三組 commit message，再用 `--expect` 分流：

```bash
--expect=ctrl-e,ctrl-c
# ctrl-c → git commit（自己寫）
# ctrl-e → git commit -e -F "$file"（改一下再送）
# enter  → git commit -F "$file"
```

每個候選 message 各寫成一個暫存檔。fzf 沒辦法在清單裡渲染多行項目，所以清單只顯示第一行標題，preview 和實際 commit 讀的是完整內容。

## 暫存與並行

### `gitsh` — staSH

stash / unstash 雙模式。開頭先看 `git stash list`，完全沒有 stash 時直接跳過模式選單進 stash 流程。

stash 模式可以多選檔案（`tab`），選完問一句 message，然後 `git stash push -- <files>`。unstash 模式列出所有 stash，preview 是 `git stash show -p`，apply 完再問要不要 drop。

preview 用了 `diff_or_stash`：先掃過所有 stash，如果這個檔案被某個 stash 收走了就顯示那個 stash 內的 diff，否則 fallback 回 `git diff HEAD`。

### `gitwt` — WorkTree

管 worktree。`Enter` 進入、`C-d` 刪除、`C-c` 新增，新增的一律放 `<root>/.worktree/<name>`，不用每次想路徑要開在哪。

進入那段有個老陷阱，子行程 cd 不動父 shell，所以只能：

```bash
# ponytail: subshell, a child process can't cd its parent shell
cd "$1" && exec "${SHELL:-/bin/bash}"
```

也就是說「進入 worktree」實際上是開一個新的 shell，離開就 `exit`。

### `gitsm` — SubModule

最單純的一支。多選 submodule 之後 `sync` 加 `update --init --recursive`，順手綁了 `ctrl-a:select-all+accept` 一鍵全選全更。preview 會顯示該 submodule 的 log，還沒 init 的就印 `not initialized`。

## 踩到的坑

**檔名有空格。** `git status --short` 會把 `a b.txt` 輸出成 `"a b.txt"`，naive 的欄位切割當場爆掉。正解是 `-z`（NUL 結尾、不 quote）配 NUL-aware 的 awk，fzf 端加 `--read0`：

```bash
git status -u -s -z | awk 'BEGIN{RS="\0"; ORS="\0"} {print substr($0,1,2) "\t" substr($0,4)}'
```

送進 `git stash push` 之前還要用 `mapfile -t` 轉陣列，不能靠 word splitting。

**fzf 按 ESC 會殺掉 `set -euo pipefail`。** abort 的 fzf 回傳非 0，`pipefail` 會讓整條 pipeline 算失敗，就算後面的 awk 成功也一樣。所以 `select_branch` 這類 helper 一律在管線尾巴補 `|| true`，讓「使用者取消」變成正常的空字串，而不是腳本直接死掉。

**preview 是另一個 subshell。** preview 指令是 fzf 另外開行程跑的，`$(dirname $0)` 在那裡不成立。得先算絕對路徑再內嵌：

```bash
GIT_UTILS_SH="$(cd "$(dirname "$0")/helpers" && pwd)/git_utils.sh"
--preview="bash -c 'source \"${GIT_UTILS_SH}\"; diff_or_stash \"\$1\"' _ {2}"
```

**WSL 的剪貼簿要用 `clip.exe`。** 從 Raycast 之類的地方非互動呼叫 `wsl.exe` 時沒有 `DISPLAY`，`xclip` 會直接失敗。`clip.exe` 不需要 `DISPLAY`，寫進去的也是 Windows 應用程式真正在讀的那個剪貼簿。

這幾個取捨在原始碼裡都留了 `ponytail:` 開頭的註解，順便標了已知天花板。像 `clip.exe` 是用當前 codepage 寫入的，非 ASCII 可能會壞，真的踩到就換 `powershell.exe -c Set-Clipboard`。

## 界線

這種工具很容易失控，寫著寫著就長成半個 lazygit。我給自己畫的線是：只補每天會打、但每次都要想一下的那幾條。需要完整 TUI 的場景，像瀏覽歷史或解衝突，交給 tig 跟 lazygit 就好。

一支腳本一個動詞，參數能用 fzf 推導的就不要求使用者打。10 支加一個 helper，總共不到 750 行 bash，還在看得懂也敢改的範圍內。

## 參考資料

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
