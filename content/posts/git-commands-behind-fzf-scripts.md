---
title: "拆開 fzf 腳本：每支背後真正在跑的 Git 指令"
date: 2026-10-29T10:55:56+08:00
draft: false
tags: [git, fzf, bash, cli, rev-parse, for-each-ref, rebase, worktree, submodule]
categories: [工程筆記]
description: "把 gitbr 等 11 支 fzf 互動腳本攤開，逐支對照背後實際執行的 git 指令，並記錄從中挖出來的 annotated tag SHA 與 autosquash 兩個 bug。"
---

## 起因

[上一篇](../interactive-git-cli-with-fzf/)講的是這些腳本怎麼設計。這篇反過來：把 fzf 那層剝掉，看每支腳本**實際**在跑哪幾條 git 指令。

理由很實際。腳本不在手邊時（別人的機器、CI、container），你還是得自己打這些指令。而且拆的過程中，我挖出了兩個藏了很久的 bug。

## 共用底層

每支腳本開頭都是同一組檢查：

```bash
git rev-parse --is-inside-work-tree   # 不在 repo 裡就結束
git rev-parse --show-toplevel         # cd 到 repo 根目錄
```

需要 `cd` 到根目錄，是因為 `git status --short` 和 `git diff --name-status` 印出的路徑都是相對於 repo 根目錄。在子目錄裡直接拿去當 pathspec 用，就會對不上。

列分支用的是 `git branch --format`，語法和 `git for-each-ref` 一模一樣，連條件式都能寫：

```bash
git branch -l --format='%(refname:short) [%(objectname:short)] %(if)%(upstream)%(then)-> %(upstream:short)%(else)<no upstream>%(end)'
```

## gitbr：查分支指向哪裡

`gitbr` 的用途是：不 checkout 也能知道一條分支指向哪個 commit、有沒有追蹤 upstream，並把 short SHA 複製到剪貼簿。核心只有三條：

```bash
git branch --show-current                          # 目前分支名稱
git rev-parse <ref>                                # ref → SHA
git rev-parse --abbrev-ref <branch>@{upstream}     # 追蹤的遠端分支
```

`<branch>@{upstream}`（縮寫 `@{u}`）指的是 `branch.<name>.merge` 設定的那條 remote-tracking branch。如果沒有設定，指令會失敗，所以腳本後面接了 `|| true`。

### 坑一：annotated tag 拿到的不是 commit SHA

```bash
$ git tag -a v1 -m v1 && git tag v1-light
$ git rev-parse HEAD v1 v1-light
c656c28...   # HEAD
dbfc2d5...   # v1 ← tag object 本身的 SHA
c656c28...   # v1-light
```

Annotated tag 是一個獨立的 object，`rev-parse` 預設回傳的是**它自己**的 SHA。所以 `gitbr -t` 複製到剪貼簿的 SHA，貼到 `git log` 可以用，但貼到 GitHub 的 commit 頁面就會查無此 commit。修正方式是 peel 到 commit：

```bash
git rev-parse "v1^{commit}"   # c656c28...
```

在 `for-each-ref` 裡對應的寫法是 `%(*objectname)`，星號代表「peel 後的 object」。

### 坑二：detached HEAD

`git branch --show-current` 在 detached HEAD 狀態下什麼都不會印。`gitbr` 不帶參數時會當成「沒選到分支」，直接結束，但 HEAD 明明有 commit。修正方式是名稱為空時直接用 `HEAD` 本身：

```bash
branch=$(git branch --show-current)
branch=${branch:-HEAD}
```

`HEAD@{upstream}` 在 detached 狀態下會失敗，剛好落到「no upstream branch」那條路徑。

### 不用腳本的替代品

```bash
git branch -vv                                         # SHA、upstream、ahead/behind
git for-each-ref --format='%(refname:short) %(upstream:track)' refs/heads
git branch --contains <sha>                            # 哪些分支含這個 commit
git branch --merged main                               # 已併入 main，可以刪
```

## 導覽類

- **`gitsw`**：從 `git branch --format='%(refname:short)'` 選一條分支，接著 `git switch`。
- **`gitco`**：`git branch --track <local> <remote>` 建立追蹤分支，再 `git switch`。直接 `git switch <name>` 其實也會自動猜出遠端分支並建立追蹤，但前提是只有一個 remote 有同名分支。
- **`gitl1`**：`git log --oneline`，`-c` 看 `<branch>..HEAD`，`-b` 看 `A...B`。兩點表示「B 有、A 沒有」；三點是 symmetric difference，也就是「兩邊各自有、對方沒有」的 commit。開 log 前先用 `git rev-list -n 1 <range>` 確認範圍不是空的。
- **`gitrl`**：`git reflog -n 100` 選一筆，然後 `git checkout <sha>`。誤 reset 之後救命用的就是這個，`HEAD@{1}` 就是上一個位置。

## 檢視與提交

- **`gitdf`**：預設 `git diff`；`-c` 是 `git diff --cached`，比較 index 和 HEAD；`-b` 是 `git diff BASE TARGET`。關掉空白差異時用 `--ignore-all-space`。
- **`gitst`**：用 `git add` / `git restore --staged` 逐檔切換 stage 狀態，接著 `git commit --fixup <sha>`，再 `git rebase -i --autosquash`。
- **`gitsh`**：`git stash push -m <msg> -- <paths>` 只 stash 選中的檔案；還原時刻意拆成 `apply` 加詢問後才 `drop`，而不用 `pop`。`pop` 遇到衝突時不會刪掉 entry，拆開寫比較好掌握狀態。

### 坑三：autosquash 的 base 給錯

`gitst` 原本是這樣寫的：

```bash
git commit --fixup "$commit"
git rebase -i --autosquash "$commit"   # ✗
```

`rebase -i <upstream>` 只會重排 `<upstream>` **之後**的 commit，目標 commit 本身不在 todo list 裡，`fixup!` 找不到可以併入的對象。實測結果：

```
6d770ce fixup! c1
a875c12 c2
0db13c6 c1
```

`fixup!` 原封不動地留在歷史裡。正確寫法是往前退一格；如果目標是 root commit，它沒有 parent，就改用 `--root`：

```bash
base="${commit}~1"
git rev-parse -q --verify "$base" > /dev/null || base=--root
git rebase -i --autosquash "$base"
```

## 改寫與並行

- **`gitrb`**：一行搞定：

  ```bash
  git rebase --onto "$ONTO" "$(git merge-base "$FROM" "$TO")" "$TO"
  ```

  把 `FROM` 和 `TO` 分岔點之後、屬於 `TO` 的 commit，搬到 `ONTO` 上。用 `merge-base` 而不是直接填 `FROM`，是為了在 `FROM` 已經往前長了之後，仍然切在正確的位置。
- **`gitwt`**：`git worktree add <path> <branch>`。分支只存在於遠端時，worktree 一樣會自動建立追蹤分支。移除用 `git worktree remove`，殘留的紀錄用 `git worktree prune` 清掉。
- **`gitsm`**：先 `git submodule sync --recursive`，讓 `.git/config` 裡的 URL 跟上 `.gitmodules`；再 `git submodule update --init --recursive`，checkout 到 superproject 記錄的 commit。只跑 `update` 不跑 `sync`，在 submodule 換過 URL 之後會一直 fetch 失敗。

## 小結

這 11 支腳本加起來，真正用到的 git 指令不到 20 條。fzf 解決的是「選」的問題，指令本身還是得懂。這次能抓出 `rev-parse` 和 `autosquash` 兩個 bug，也是因為把指令拆出來一條一條實測，而不是靠記憶。

## 參考資料

- [git-rev-parse(1) Manual Page](https://git-scm.com/docs/git-rev-parse)
- [git-for-each-ref(1) Manual Page](https://git-scm.com/docs/git-for-each-ref)
- [git-branch(1) Manual Page](https://git-scm.com/docs/git-branch)
- [gitrevisions(7) Manual Page](https://git-scm.com/docs/gitrevisions)
- [git-rebase(1) Manual Page](https://git-scm.com/docs/git-rebase)
- [git-stash(1) Manual Page](https://git-scm.com/docs/git-stash)
- [git-submodule(1) Manual Page](https://git-scm.com/docs/git-submodule)
