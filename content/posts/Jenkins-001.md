---
title: "[Unity, Jenkins] Using Jenkins build and shipping Unity3d project to Google Play, App Store, Mac App Store and Steam (1)"
date: 2019-12-06T03:41:00+08:00
tags: ["Unity", "Jenkins"]
draft: true
---

記錄一下目前工作中使用 Jenkins 編譯 Unity 並自動上傳到各平台後台的一些心得跟做法

預計會分成幾篇來介紹

Jenkins 架設篇
Server

我們使用 docker 來架設 jenkins 的主機，因此可以在未來升級硬體時很輕易的將環境移轉。另外有設定內部的 dns 來指向 server，換主機的時候也可以將 dns 更新就不需要通知所有人更新書籤。

首次使用可以用 docker run 建立容器 (Ref. Docker docs: docker run)

[code language="text"]
docker run
--name my-jenkins
-p 8080:8080
-p 50000:50000
-v ~/jenkins_home:/var/jenkins_home
jenkins/jenkins:lts
[/code]
name: 幫 container 命名 (讓下次啟動時不用建立新的容器)
p (port):
8080 是網頁用的 port 可以依據需求修改
50000 是給 agent 用的 port
v (volume): 用來指定資料儲存的目錄
jenkins_home 是 jenkins 的主資料夾，包含了設定跟工作目錄
jenkins/jenkins:lts 是使用的 image
jenkins/jenkins 是 image 的名稱
lts 是 image 的 tag。（lts 是 long term support 的縮寫)

之後只需要用 `docker start` 命令啟動上次的容器即可 (Ref. Docker docs: docker start)

[code language="text"]docker start -a my-jenkins[/code]
a (attach): 要啟動的容器名稱
Node (Agent)

我們在規劃 Node 以及 Node 的執行程式數量的考量如下：

目前不允許多個 Unity 應用程式同時開啟同一個專案（batchmode 或是 Editor 同時只能有一個開啟)，但是同一個 Unity 應用程式可以同時開啟不同專案。
設計時要注意專案的設定需要勾 Do not allow concurrent builds 避免同時執行。
Node 設定使用環境參數來設定 Node 上的工具路徑
腳本 (Jenkinsfile) 中不要寫死路徑，使用環境參數讓專案更容易在不同 Node 中執行，也可以讓擴充更容易。
如果機器夠的話，可以增加 Node 並且把需要的環境參數以及標籤 (Label) 設定好並且將需要的程式安裝好，應該可以在不用修改 jenkinsfile 的情況下順利執行工作。