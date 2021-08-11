---
title: "Ruby Notes - 001"
date: 2021-08-12T01:08:01+08:00
tags: ["Ruby"]
draft: true
---

# 變數與常數

## 變數

- Ruby 的變數或是常數都不需要宣告就可以使用、也不需要指定型別
- Ruby 的變數命名與其範圍有關
    - 區域變數 （local variable） - 非大寫字母開頭的名字 (Ex. `name`)
        - Rubocop 建議不使用的變數可以加上 `_` 前綴
    - 全域變數 （global variable） - 前綴 `$` 的變數 (Ex. `$name`)
        - 如同所有程式語言的建議，盡量避免宣告全域變數
    - 實體變數 （instance variable） - 前綴 `@` 的變數 (Ex. `@name`)
        - 相同類別的物件分別擁有自己的變數，不會互相影響
    - 類別變數 （class variable） - 前綴 `@@` 的變數 (Ex. `@@name`)
        - 相同類別的物件共同擁有相同的變數

- 虛擬變數（Pseudo Variable）
    - 內部定義的變數，不可更改
        - `true`
        - `false`
        - `nil`
            - 表示沒有物件的關鍵字，對 nil 的操作通常會拋出例外
                - ```NoMethodError: undefined method `name' for nil:NilClass```
            - Ruby 的 `nil` 是個特殊的物件，幾乎沒有任何方法與成員
        - `self`


## 常數

- 大寫英文字母開頭
- **IMPORTANCE**: 常數仍然可以被賦值，雖然會有警告但是不會造成錯誤


## 命名慣例

- Ruby 變數的命名慣例為 **Snake Case** (全小寫，單字以底線分隔) (Ex. `my_name`)
- 類別名稱、模組名稱、方法名稱可以視為常數，使用 **Upper Camel Case** (單字首字大寫) (Ex. `MyClass`)


## 指定 / 賦值

- Ruby 支援多種形式的多重指定

```Ruby
x, y, z = 1, 2, 3 # x = 1, y = 2, z = 3
x, y, z = [1, 2, 3] # x = 1, y = 2, z = 3

# 等號右邊的數量比等號左邊的數量多的時候 => 忽略多的數值
x, y = 1, 2, 3 # x = 1, y = 2
x, y = [1, 2, 3] # x = 1, y = 2
# 如果等號左邊的最後一個變數加上星號(*)時，將剩餘未分配的數值合併成陣列指定給最後的變數
x, *y = 1, 2, 3 # x = 1, y = [2, 3]
  # * 表示接收剩下來的參數為陣列

# 等號右邊的數量比等號左邊的數量少的時候 => 缺少的部分成為 nil
x, y, z = 1, 2 # x = 1, y = 2, z = nil
x, y, z = [1, 2] # x = 1, y = 2, z = nil

# 成員中包含陣列時可以使用 () 解開陣列
x, y, z = [1, [2, 3]] # x = 1, y = [2, 3] z = nil
x, (y, z) = [1, [2, 3]] # x = 1, y = 2, z = 3
x, (y, z) = [1, 2, 3] # x = 1, y = 2, z = nil
```

- Ruby 可以用多重指定做到 swap
    - `x, y = y x`
- C# & C++ 也有類似多重指定的語法支援，但是使用上的限制比 ruby 還多
    - C# -> Deconstructor
    - C++ 17 -> Structured binding declaration


# 註解

- 單行註解
    - `#` 以後的都是註解

```ruby
# Comment
temp = nil # Temp is Nil
```

- 多行註解
    - `=begin` 以及 `=end` 包起來的範圍都是註解

```ruby
=begin
Comment 1
Comment 2
...
=end
```

- **NOTE**: 單行註解比較實用


# 流程控制

- 只有 `nil` 或是 `false` 會被當成 `false`
    - 數字的 0 也是 `true` 跟 C++/C# 不同

## **if ... elsif ... else**

```ruby
if condition then
  # Do something 1
elsif condtion then
  # Do something 2
else
  # Do something 3
end
```

- 其中的 `then` 可以省略
- 其中的 `else` 區塊或是 `eleif` 區塊也可以省略
- **NOTE:** 關鍵字是用 `elsif`

