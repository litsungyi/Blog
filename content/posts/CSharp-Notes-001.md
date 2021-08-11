---
title: "C# Notes - 001"
date: 2021-08-12T01:08:01+08:00
tags: ["C#"]
---

# 型別宣告

在 C# 中宣告變數的語法如下：

```
type name [= initial_value];
```

- *type* 是變數的型別（例如： `int`, `bool`, `string`）。 
- *name* 是變數的名稱。
- *initial_value* 是變數的初始值，沒有指定時初始值為其預設值。
  - **Value Type** 的預設值是 `0` or `false`。
  - **Reference Type** 的預設值是 `null`


# `Value Type` v.s. `Reference Type`

C# 的變數可以分類成兩種類型：`Value Type（值類型）` 以及 `Reference Type （參考類型）`。

`Value Type` 包含以下型別： `bool`，整數型別，浮點數型別以及使用 `struct` 關鍵字宣告的自訂型別。 

`Reference Type` 包含以下型別： `string`以及使用 `class` 關鍵字宣告的自訂型別。 

兩種類型最大的差異在於記憶體的管理方式不同。


## Value Type

## Reference Type

