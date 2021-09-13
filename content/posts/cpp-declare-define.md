---
title: "C++ - 宣告 vs. 定義"
date: 2020-06-29T17:23:06+08:00
draft: false
tags: ["c++"]
---


# Declare 宣告

- 宣告是指程式中使用到某個類別或是變數之前，先讓編譯器知道該類別的名稱或是變數的類別與名稱。
- 必須要在實際使用之前宣告。因此在標頭檔以及原始檔之中需要使用 `#include` 這個預處理器命令將用到的類別介紹給編譯器。
    - `#include` 這個預處理器命令實際上是將引入的檔案內容取代掉 `#include` 所在的位置，因此大量的 `#include` 會大幅增加編譯的時間。
    - 如果只用到指標或是參考時，在標頭檔可以使用前置宣告 (Forward Declare) 的技巧來優化。（細節在 **前置宣告** 小節中說明）
        - 不呼叫該指標的方法或是使用它的成員時，編譯器不需要知道該類別的形狀，只需要當成該類型的指標變數來處理。因為指標的大小是固定的，所以不需要引入該類別也可以通過編譯。
- 相同的宣告可以在專案中重複出現。


# Define 定義

- 定義是編譯器提供類型實作細節的地方，以及配置變數記憶體的語句。
    - 因為定義變數時需要配置記憶體在 stack 上，因此編譯器在此時必須要知道此類別的記憶體佈局（成員的順序與類型、記憶體對齊方式等...）。
- 與宣告不同的是，定義在程式中只能出現一次。重複定義會造成錯誤。
    - 同一個轉換單元（Translation Unit）之中只能定義一次，否則會有編譯錯誤。
    - 同專案中不同轉換單元之中也只能定義一次，否則會有連結錯誤。
- 所有程式中有用到的實體（變數、函式...）都必須也只能在其中一個轉換單元中定義，否則會有連結錯誤。


## `extern` 關鍵字

- 在多個轉換單元之間，如果要使用同一個變數的實例可以將變數宣告為外部引用（extern），讓編譯器在連結期再把實際的變數實例連結到使用的程式碼。


# Forward Declare 前置宣告

- 需要使用前置宣告通常有兩種原因
    1. 因為編譯器必須先看到類別、函式的宣告才能在接下來的程式中使用，一但出現互相引用的狀況編譯器就無法處理。例如底下兩個程式碼就無法編譯：

``` cpp
void TestFunction()
{
    TestClass test; // error: unknown type name 'TestClass'
}

class TestClass
{
public:
    void Test()
    {
        TestFunction();
    }
};
```

``` cpp
class TestClass
{
public:
    void Test()
    {
        TestFunction(); // error: use of undeclared identifier 'TestFunction'
    }
};

void TestFunction()
{
    TestClass test;
}
```

- 不論是先定義 TestFunction 還是先定義 TestClass，都會在使用到對方的程式碼的時候發生編譯錯誤。
- 前置宣告的作法就是把其中一個的定義語法改成宣告語法，先讓編譯器知道名稱、型別資訊來避免編譯錯誤。


``` cpp
void TestFunction(); // NOTE: Forward declare

class TestClass
{
public:
    void Test()
    {
        TestFunction();
    }
};

void TestFunction()
{
    TestClass test;
}
```


2. 更常見的原因是為了提升編譯速度。當某個類別的方法參數、成員變數需要其他型別時，我們就需要在標頭檔之中引用其他標頭檔。因為 #include 是將引用的檔案展開到 #include 的位置，當引入的數量很多的時候會有大量的 IO 發生。通常標頭檔還會被其他檔案引用，造成倍數的成長。
    - 如果是方法的參數或是成員變數用到指標或是參考時，編譯器要知道保留多少空間來儲存這個參數。幸運的是指標或是參考的大小都是固定的，因此編譯器並不需要知道整個類別的記憶體佈局。所以使用前置宣告可以減少需要引入的標頭檔數量。
    - 減少需要引入的標頭檔數量還可以減少因為修改檔案時需要重新編譯的檔案數量。


## 前置宣告的缺點

- 根據 [Google C++ Style Guide](https://google.github.io/styleguide/cppguide.html) 並不建議使用前置宣告。
- 使用前置宣告可能造成對 incomplete type 的操作，這在 C++ 標準是未定義行為(Undefine Behaviour)，因此無法保證程式是否能更正確運行。
    - 在 #include 該型別的定義之前絕對不要對該型別做操作。
        - 大部分的情況部會有問題，而且誤用時也會有編譯錯誤。但是像是 delete 指標、將指標當成參數是可以通過編譯的（會有警告）。


Ref: https://docs.microsoft.com/zh-tw/cpp/cpp/declarations-and-definitions-cpp?view=vs-2019