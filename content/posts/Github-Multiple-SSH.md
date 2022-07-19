---
title: "GitHub Multiple SSH"
date: 2022-07-19T15:16:33+08:00
---

# Introduction

如果有多個 GitHub 帳號 (個人帳號與工作用的帳號) 都要使用 SSH 連線，因為在同一台電腦上無法使用同一個 SSH Key 綁定到不同的帳號，所以會需要做一些設定才可以使用。

# Setting

1. 首先要先幫兩個帳號都產生一組 SSH Key
   可以參考 GitHub 的說明 [Generating a new SSH key and adding it to the ssh-agent](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)

   `ssh-keygen -t ed25519 -C "personal_mail@personal.com"`
   `ssh-keygen -t ed25519 -C "work_mail@company.com"`

2. 並且將兩個帳號都分別註冊到 GitHub 設定頁面
   [Adding a new SSH key to your GitHub account](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account)

   記得兩個帳號都要設定，需要分別登入兩個帳號並且將 public key 註冊。

3. 接下來需要修改你的 ssh 設定檔： 開啟並編輯 `~/.ssh/config`
   加上以下設定到檔案中，請依照你前面創造的 ssh 來設定你的設定檔。

```
# Personal account
Host github.com
   HostName github.com
   IdentityFile ~/.ssh/personal_private_key
   IdentitiesOnly yes
   
# Work account
Host github-company
   HostName github.com
   IdentityFile ~/.ssh/work_private_key
   IdentitiesOnly yes
```

   **NOTE**: 注意第二個 github 需要幫它取別名。 checkout 的時候要改用這個別名。
             如果原本的路徑是 `git@github.com:your-company/your-repository.git`
             clone 的時候要把 github.com 改成你剛剛設定的別名

```
git clone git@github-company:your-company/your-repository.git
```

4. 最後可以測試一下是不是可以正常連線

```
ssh -T git@github.com
ssh -T git@github-company
```

如果每次都需要改變連線網址會相當麻煩，可以再做以下設定來解決。

5. 開啟並編輯 `~/.gitconfig` ，並且新增以下設定。這樣就不用修改 git clone 的網址。

```
[url "git@github-company:your-company/"]
    insteadOf = git@github.com:your-company/
```

# Reference

- https://gist.github.com/oanhnn/80a89405ab9023894df7
