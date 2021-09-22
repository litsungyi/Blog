---
title: "[Unity, Jenkins] Using Jenkins build and shipping Unity3d project to Google Play, App Store, Mac App Store and Steam (2)"
date: 2019-12-06T03:41:00+08:00
tags: ["Unity", "Jenkins"]
draft: true
---

# [Unity, Jenkins] Using Jenkins build and shipping Unity3d project to Google Play, App Store, Mac App Store and Steam (2)

架設好 Server 之後，接下來就要開始設置建置作業 (Job) 了。

Job
在新增作業時，我們選擇 Pipeline 的形式
首先要勾選 Do not allow concurrent builds 避免專案同時執行
另外勾選參數化建置參數的設定會跟 Jenkinsfile 的設計有關，晚一點會提到。
最後在 Pipeline 的地方選擇 Pipeline script from SCM
使用這個選項需要將 Jenkinsfile 腳本簽入 Git 中
最後在 Script Path 指定要執行的 Jenkinsfile 的名稱
Ref. https://jenkins.io/solutions/pipeline/




Groovy

Jenkinsfile 使用 Groovy 語言寫，語法不難，不過有一些常寫錯的語法要注意一下

變數使用 def 宣告，使用時不需要加 $ 或 ${}（只用在字串替換中），容易跟字串的替換搞混要注意。
Groovy 字串的格式有四種
雙引號可以將變數替換、單引號則不行。
三個單引號與雙引號都是多行字串，差異只在有沒有變數替換而已。
[code language="groovy"]
def name="emeth"
def str1='hello ${name}'
echo('str1: ' + str1)
def str2="hello ${name}"
echo('str2: ' + str2)
def str3='''hello
${name}'''
echo('str3: ' + str3)
def str4="""hello
${name}"""
echo('str4: ' + str4)
[/code]

以上的結果將是

[code language="text"]
str1: hello ${name}
str2: hello emeth
str3: hello
${name}
str4: hello
emeth
[/code]