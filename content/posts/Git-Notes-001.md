---
title: "Git Notes - 001"
date: 2021-08-12T01:08:01+08:00
tags: ["git"]
draft: true
---

# 初始化

在資料夾輸入 `git init` 可以初始化 git 儲存庫，會在目前資料夾中建立一個 `.git` 的資料夾，裡面包含 git 需要的資訊。
- {{< fas-icon name="file" >}} HEAD: 目前的位置，通常會指向目前 branch 的末端
- {{< fas-icon name="file" >}} config: Git 的設定檔
- {{< fas-icon name="file" >}} description: Git 的說明
- {{< fas-icon name="folder" >}} hooks: 包含預設的 hooks 模板 (副檔名為 .sample，git 會忽略這些檔案)
- {{< fas-icon name="folder" >}} info: ?
- {{< fas-icon name="folder" >}} objects: 存放所有 Git 檔案的內容，目前還是空的資料夾
  - {{< fas-icon name="folder" >}} info:
  - {{< fas-icon name="folder" >}} pack:
- {{< fas-icon name="folder" >}} refs: 存放所有 Git 分支 (branch) 以及標籤 (tag) 的資訊
  - {{< fas-icon name="folder" >}} heads:
  - {{< fas-icon name="folder" >}} tags:


# objects 資料夾

在加入檔案之後， object 資料夾就會發生變化， git 會紀錄每次加入的檔案內容。

檔案的名稱對 git 而言並不重要， git 紀錄的是檔案的內容經過 SHA1 雜湊之後的值。

任何內容經過 SHA1 運算之後都是 160 bits 的內容，轉換成 16 進位就變成 40 個字元的字串。
Git 會將檔案的內容放在 `.git/objects` 裡面，並且以 SHA1 的值命名。

為了避免檔案過多造成存取效能變差， git 會將檔案分成兩層，先將 SHA1 的前 2 個字元取出作為資料夾名稱，剩下的 38 個字元作為檔案名稱。

Ex. 空白檔案的 SHA1 是 `e69de29bb2d1d6434b8b29ae775ad8c2e48c5391` 如果用 `git add` 將檔案加到 index，該檔案就會被存到 `.git/objects/e6/9de29bb2d1d6434b8b29ae775ad8c2e48c5391`

{{< highlight shell "linenos=table" >}}
touch test
git add test
{{< / highlight >}}

**NOTE**: 空資料夾

由於 git 只關注內容，對於檔案名稱並不在意。因此，資料夾是無法被加到 git 中。

想要將空資料夾加到 git 中，可以在這個資料夾內建立一個空檔案（習慣上會命名為 `.gitkeep` or `.keep`）然後 commit 這個檔案。 


## Blob (Binary Large OBject), Tree, Commit, Tag

在說明之前，先簡單較少等一下會用到的兩個指令。

`git cat-file -t SHA1` 可以顯示這個 SHA1 檔案對應的類型是什麼。回傳結果會是 `blob`, `tree`, `commit`, `tag` 的其中一個。

由於 `.git/objects` 裡面的內容是壓縮過的，想要看到原始的內容可以用 `git cat-file -p SHA1` 顯示。

----


