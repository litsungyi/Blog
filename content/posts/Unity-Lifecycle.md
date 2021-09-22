---
title: "[Unity] MonoBehaviour 生命週期研究 (1)"
date: 2019-12-06T03:41:00+08:00
tags: ["Unity", "C#"]
draft: true
---

# [Unity] MonoBehaviour 生命週期研究 (1)

要了解 MonoBehaviour 生命週期
必須用 Unity 官方的這張 Script lifecycle flowchart 來說明

[img]: https://i.imgur.com/qZY9Xqg.png

Ref. Execution Order

這篇文章會偏重在生成與消滅相關的函式：

Awake(), OnEnable(), Start(), OnDisable(), OnDestroy()

跟更新有關的函式會在另外的文章中說明

Awake

在物件的生命週期中 Awake() 只會被呼叫一次
而且一定是所有 MonoBehaviour 內建函式中第一個被呼叫的

在以下幾種情形 Unity 會呼叫 Awake()

當 GameObject 在場景（Scene）上並且此 GameObject 是 Active 而且 MonoBehaviour 是 Enable 的時候
載入此場景的時候會呼叫 Awake()
當 GameObject 在 Prefab 上並且此 GameObject 是 Active 而且 MonoBehaviour 是 Enable 的時候
將這個 Prefab 實體化到場景中的時候會呼叫 Awake()
當 MonoBehaviour 被生成並 AddComponent 到場景上的 Active 的 GameObject 的時候
Unity 會呼叫該 GameObject 上所有 Active 的 MonoBehaviour  的 Awake()



Start

OnDestroy