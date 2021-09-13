---
title: "C++ - 命名規則"
date: 2020-06-29T14:13:50+08:00
tags: ["C++"]
---


# General Rule

- 程式中的所有類別、變數、函式...的命名請務必使用讓人看到名稱就可以了解他的用途。
  - 使用註解來解釋是不得已的作法，請盡量避免。
- 名稱的長度沒有限制，但是請以人類容易閱讀、記憶的原則命名，過長或過短的名稱都不適當。
  - 避免無法發音的名稱或是外語的羅馬拼音，除非這是所有成員都理解的專有名稱或是 **領域用語**。
  - 不要使用自創的縮寫。
  - 使用縮寫請確保團隊成員都清楚縮寫的意義。
- 命名時請考慮使用共同的 **領域用語**，降低與其他成員溝通的成本。
  - 團隊應該建立自己的 **字彙表** 提供團隊成員查詢專案使用的 **領域用語**。


# 引用防護（include guard）命名

- 使用 ALL_CAPS （全大寫命名法）命名。命名規則使用檔案完整路徑並且加上 `__` 前綴。（Ex. `__BATTLE_FLElD_H`）
  - 建議改用 `#pragma once` 取代引用防護，編譯器能對 `#pragma once` 做較好的最佳化。


# 全域變數命名

- 使用 lower camel case （小駝峰式命名法）命名，並且加上 `g_` 前綴。（Ex. `bool g_battleField`）
  - 請避免使用全域變數。


# 區域變數命名

- 使用 lower camel case （小駝峰式命名法）命名。（Ex. `bool battleField`）


# 常數命名

- 使用 ALL_CAPS （全大寫命名法）命名。（Ex. `const bool BATTLE_FLAG`）


# 命名空間命名

- 使用 upper camel case （大駝峰式命名法）命名。（Ex. `namespace BattleField`）


# 函式命名

- 函式使用 lower camel case （小駝峰式命名法）命名。（Ex. `void battleFunction()`）
- 參數使用 lower camel case （小駝峰式命名法）命名。（Ex. `void battleFunction(bool battleFlag)`）


# 列舉命名

- 使用 upper camel case （大駝峰式命名法）命名。（Ex. `enum BattleField`）


## 列舉值命名

- 使用 upper camel case （大駝峰式命名法）命名。（Ex. `Empty = 0`）
  - 盡量給所有列舉值初始值，避免程式改動後數值錯亂。
- 命名時請不要重複列舉的名稱。
  - GOOD: ```enum BattleField { Empty = 0, Full = 1, };```
  - BAD: ```enum BattleField { BattleFieldEmpty, BattleFieldFull, };```


# 類別命名

- 使用 upper camel case （大駝峰式命名法）命名。（Ex. `class BattleField`）


## 類別成員命名

- public 成員使用 lower camel case （小駝峰式命名法）命名 （Ex. `bool battleFlag`）。
  - 請只在 struct 中使用 public 成員。
- protected 、 private 成員使用 lower camel case （小駝峰式命名法）命名，並且加上 `_` 前綴。（Ex. `bool _battleFlag`）。


## 類別方法/類別靜態方法命名

- 函式使用 lower camel case （小駝峰式命名法）命名 （Ex. `void battleFunction()`）
- 參數使用 lower camel case （小駝峰式命名法）命名 （Ex. `void battleFunction(bool battleFlag)`）


## 類別靜態成員命名

- 使用 lower camel case （小駝峰式命名法）命名，並且加上 `s_` 前綴。 （Ex. `static bool s_battleFlag`）。


## 類別成員常數/類別靜態成員常數命名

- 使用 ALL_CAPS （全大寫命名法）命名。 （Ex. `static const bool BATTLE_FLAG`）。

