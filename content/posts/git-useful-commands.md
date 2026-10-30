---
title: "常用的 git 指令"
date: 2026-08-31T11:42:11+08:00
draft: false
tags: [git, fetch, pull, push, reset, rebase, commit]
categories: [工程筆記]
description: "整理 fetch/pull/push 與 reset/commit/rebase 這六條天天在用的指令，重點放在 --prune、--rebase、--force-with-lease、--fixup、--autosquash 這幾個會改變行為的參數。"
images: ["images/Header/git-useful-commands.jpg"]
---

![常用的 git 指令](/Blog/images/Header/git-useful-commands.jpg)

## 起因

`git fetch`、`git pull`、`git push` 這三條指令，不加參數的行為大家都會。但真正會讓事情變好或變糟的，都是那幾個平常沒在打的參數。

同樣地，`git reset`、`git commit`、`git rebase` 本身不難，難的是「commit message 打錯了要怎麼補」「已經 push 出去的分支要怎麼整理」這種當下會卡住的情境。

這篇整理我最常用到的六條，以及各自那個關鍵參數。

## 同步遠端：fetch / pull / push

### `git fetch --prune`

`git fetch` 能把遠端的 ref 抓回來更新本地的 remote-tracking branch（`origin/xxx`），不動你的工作目錄，也不動你的本地分支。

問題在於它**只增不減**。同事把 `origin/feature/login` 合併後刪掉了，你這邊的 `origin/feature/login` 還會一直留著，`git branch -r` 越看越髒，用 fzf 之類的工具列清單時更明顯。

`--prune`（縮寫 `-p`）就是拿來清這個的：把遠端已經不存在的 remote-tracking branch 一併刪掉。

```bash
git fetch --prune
git fetch -p           # 同上
git fetch --prune --prune-tags   # 連遠端刪掉的 tag 一起清
```

注意 `--prune` 刪的是 `origin/xxx` 這種 remote-tracking ref，**不會**動到你本地那條同名分支。合併完留下的本地分支還是要自己 `git branch -d`。

### `git pull --rebase`

`git pull` 的本質是 `git fetch` + `git merge`。當你和遠端各自有新的 commit 時，預設的 merge 會產生一個 `Merge branch 'main' of ...` 的 merge commit——這種 commit 不記錄任何決策，純粹是同步造成的雜訊。

`--rebase` 把第二步換成 `git rebase`：先把你的本地 commit 收起來，快轉到遠端的最新狀態，再把你的 commit 一個一個重播上去。歷史變成一條直線，沒有多餘的 merge commit。

```bash
git pull --rebase
git config --global pull.rebase true   # 設成預設
```

代價是**你的 commit 會被重寫**（SHA 全變）。所以規則是：只對「還沒推出去的本地 commit」用 rebase。已經 push 出去、別人可能已經接手的 commit，用 rebase 重寫就會製造麻煩。

如果你的分支上有刻意保留的 merge commit（例如把 feature 分支合進來的那個），用 `--rebase=merges` 才不會被壓平。

衝突處理方式也不同：merge 是一次解完所有衝突，rebase 是**每一個 commit 各解一次**。commit 多的時候會解到懷疑人生，這時 `git rebase --abort` 退回去改用 merge 反而快。

### `git push --force`

rebase 或 amend 之後，本地歷史和遠端已經對不起來，一般的 `git push` 會被拒絕。這時候需要強制推送。

但 `--force`（`-f`）是真的**完全不管**遠端現在是什麼狀態，直接用你的版本蓋掉。如果在你 rebase 的這段時間內，同事推了新的 commit 上去，這一推就把他的東西刪乾淨了，而且沒有任何提示。

正解是 `--force-with-lease`：

```bash
git push --force-with-lease
```

它多一道檢查——遠端目前的位置，必須和你本地記錄的 `origin/xxx` 一致才推。也就是「遠端從我上次 fetch 之後沒有變過」才動手，有變就拒絕。

有個容易踩的陷阱：`--force-with-lease` 比對的是本地的 remote-tracking ref，所以任何會更新它的操作——包含你隨手打的一次 `git fetch`、或是背景自動跑 fetch 的 IDE——都會讓這道保險失效。Git 2.30 之後加了 `--force-if-includes` 來補這個洞，它要求「遠端目前那個 commit 必須已經被我的分支包含進去」：

```bash
git push --force-with-lease --force-if-includes
```

特別注意：**不要對其他人會共用的 branch（`main`、`dev` 等）force push**。只對自己的 feature branch 用，共用分支另外設分支保護規則比較實在。

## 整理歷史：reset / commit --fixup / rebase --autosquash

### `git reset` 與改 commit message

`git reset` 做的事是「把 HEAD 移到某個 commit」，差別在工作目錄和索引跟不跟著動：

| 模式 | HEAD | 索引（staged） | 工作目錄 |
| --- | --- | --- | --- |
| `--soft` | 移動 | 保留 | 保留 |
| `--mixed`（預設） | 移動 | 重設 | 保留 |
| `--hard` | 移動 | 重設 | **覆蓋** |

只有 `--hard` 會真的吃掉你的檔案修改，另外兩個都只是在調整「這些改動目前算在哪一層」。

最常見的用途是 commit message 打錯：

```bash
git reset --soft HEAD^   # 回到上一個之前，改動全部留在索引裡
git commit               # 重新寫一次 message
```

`HEAD^` 是「HEAD 的第一個 parent」，也就是上一個 commit。這裡一定要用 `--soft`，用預設的 `--mixed` 會連 staged 狀態一起丟掉，還得重 `git add` 一次。

不過如果只是要改**最新那個**的 message，`--amend` 更直接：

```bash
git commit --amend                 # 開編輯器改 message
git commit --amend -m "new msg"    # 直接給新的 message
git commit --amend --no-edit       # message 不動，只把新 staged 的東西併進去
```

兩者的分界很清楚：改一個用 `--amend`，要把最近三個併成一個才輪到 `git reset --soft HEAD~3` 然後重 commit。

共同點是**兩者都會產生新的 SHA**。已經推出去的話，就會需要上面那條 `--force-with-lease`。

### `git commit --fixup`

上面的招數都只能處理「最新」的 commit。但實務上更常遇到的是：review 時發現三個 commit 前的某個檔案漏改了一行。

這時候不要另外開一個 `fix typo` 的 commit 丟在最後面——那個 commit 對讀歷史的人沒有任何意義。用 `--fixup` 標記它屬於哪一個：

```bash
git add path/to/file
git commit --fixup <target-sha>
```

它會產生一個 message 是 `fixup! <目標 commit 的標題>` 的 commit。內容照樣是你這次的改動，但標題裡帶著「我要被併回那個」的資訊。

幾個變體：

- `git commit --squash <sha>`：一樣是併回去，但**保留**這次的 message，之後會和目標 commit 的 message 合在一起讓你編輯。
- `git commit --fixup=amend:<sha>`：連目標 commit 的 message 一起改掉。
- `git commit --fixup=reword:<sha>`：只改 message，不帶任何檔案改動。

### `git rebase --autosquash`

`--fixup` 只負責「標記」，真正把 commit 搬回定位的是 `--autosquash`：

```bash
git rebase --autosquash <base>
```

它會掃過待 rebase 的 commit，凡是 message 以 `fixup!` / `squash!` / `amend!` 開頭的，就自動排到對應的目標 commit 後面，並把動作標成 `fixup`、`squash` 或 `fixup -C`（`amend!`）。原本要手動剪貼 rebase todo 的步驟整個省掉。

`--autosquash` 底層走的是 interactive 的機制，但從 Git 2.44 起不需要顯式加 `-i`——不加就是直接執行、不開編輯器讓你確認（更舊的版本 `--autosquash` 只能搭配 `-i` 使用）。想先看一眼排出來的 todo 再決定，就加 `-i`。我通常會用 `-i` 模式，順便調整要 commit 的順序跟方式（`pick`、`reword`、`squash`、`drop` 等）。

同樣可以設成預設（只對 interactive 模式生效）：

```bash
git config --global rebase.autoSquash true
```

搭起來的完整流程是這樣：

```bash
git commit --fixup <sha>          # 補一個，標好目標
git commit --fixup <another-sha>  # 可以補很多個
git rebase --autosquash -i <base> # 確認 todo 的排序與動作
git push --force-with-lease       # 推上去
```

平常開發時想到什麼補什麼，送 PR 前再一次整乾淨。歷史保持可讀，過程中又不用一直中斷手上的事去做 rebase。

我在發 PR 請其他人 review 之前，都會用這個方式整理 commit，讓 commit 歷史更好讀。

## 參考資料

- [git-fetch(1) Manual Page](https://git-scm.com/docs/git-fetch)
- [git-pull(1) Manual Page](https://git-scm.com/docs/git-pull)
- [git-push(1) Manual Page](https://git-scm.com/docs/git-push)
- [git-reset(1) Manual Page](https://git-scm.com/docs/git-reset)
- [git-commit(1) Manual Page](https://git-scm.com/docs/git-commit)
- [git-rebase(1) Manual Page](https://git-scm.com/docs/git-rebase)
- [Git Tools - Rewriting History — Pro Git](https://git-scm.com/book/en/v2/Git-Tools-Rewriting-History)
- [--force considered harmful; understanding git's --force-with-lease — Atlassian](https://blog.developer.atlassian.com/force-with-lease/)
- [Auto-squashing Git Commits — thoughtbot](https://thoughtbot.com/blog/autosquashing-git-commits)
- [Git commit fixup and autosquash — Sebastian Daschner](https://blog.sebastian-daschner.com/entries/git-commit-fixup-autosquash)
