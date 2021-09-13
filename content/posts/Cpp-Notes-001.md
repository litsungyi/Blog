---
title: "C++ Notes - 001"
date: 2021-09-02T02:52:41+08:00
tags: ["C++", "C++ 11"]
draft: true
---

# C++ Notes - 001 - C++ 11 New features

## RAII - Resource acquisition is initialization

RAII 是一種常用來防止記憶體洩漏的方式。記憶體在被 new 出來之後就立即被物件建構式取得並管理，並且在物件的解構式中釋放。

## Smart Pointers

### std::auto_ptr

