---
title: "C++ - User-defined literals"
date: 2023-03-01T03:10:00+08:00
tags: ["C++", "C++ 11"]
---


C++ 11 新增 User-defined literals 可以經由程式定義的字面常量後綴，讓我們寫出可讀性更加的程式碼。


> 簡單的說，我們可以透過有意義的字面常量後綴將常數或是字串轉換自訂的型別來提高可讀性。


## User-defined literals

目前 User-defined literals 支援以下 8 種語法格式：

1. `decimal-literal ud-suffix`
2. `octal-literal ud-suffix`
3. `hex-literal ud-suffix`
4. `binary-literal ud-suffix`
5. `fractional-constant exponent-part ﻿(optional) ud-suffix`
6. `digit-sequence exponent-part ud-suffix`
7. `character-literal ud-suffix`
8. `string-literal ud-suffix`


* 1-4 支援不同進位的整數格式
* 5, 6 支援不同格式的浮點數
* 7 支援字元格式
* 8 支援字串格式
* 使用者定義的 `ud-suffix` 需要以底線 `_` 開頭，標準函式庫中定義的則不會以底線開頭。

編譯器在遇到 User-defined literals 的時候會依據 `ud-suffix` 前面的文字的型別推導適當的函式進行轉換。

首先會透過 unqualified name lookup 找到所有名稱符合的函式集合。

* 如果是整數格式：
  * 如果符合的函式集合有參數型別為 `unsigned long long` 時，會選擇此函式並呼叫 `operator ""X(nULL)`。
  * 否則，如果有參數型別為 `raw literal operators` (`const char*`)時，會選擇此函式並呼叫 `operator ""X("n")`。
  * 否則，如果有參數型別為 `numeric literal operator template` (`template<char ...> X operator ""X()`) 時會選擇此函式並呼叫 `operator ""X<'C1', 'C2', ..., 'CK'>()`。
* 如果是浮點數格式：
  * 如果符合的函式集合有參數型別為 `long double` 時，會選擇此函式並呼叫 `operator ""X(fL)`。
  * 否則，如果有參數型別為 `raw literal operators` (`const char*`)時，會選擇此函式並呼叫 `operator ""X("f")`。
  * 否則，如果有參數型別為 `numeric literal operator template` (`template<char ...> X operator ""X()`) 時會選擇此函式並呼叫 `operator ""X<'C1', 'C2', ..., 'CK'>()`。
* 如果是字串格式：
  * (C++ 20) 如果有符合的 `non-type template parameter of class type` (`string literal operator template`)時，會選擇此函式並呼叫 `operator ""X<str>()`。
  * 否則會選擇此函式並呼叫 `operator ""X (str, len)`。
* 如果是字元格式：
  * 會選擇此函式並呼叫 `operator ""X(ch)`。


## Literal operators / Literal operators template

* Literal operators 需要符合以下格式：
  * `operator "" identifier` (deprecated in C++23)
    * "" 與 identifier 之間有空格
  * `operator user-defined-string-literal`
    * "" 與 identifier 之間沒有空格
  * parameter list 只允許以下類型
    * `( const char * )`
    * `( unsigned long long int )`
    * `( long double )`
    * `( char )`
    * `( wchar_t )`
    * `( char8_t )`	(since C++20)
    * `( char16_t )`
    * `( char32_t )`
    * `( const char * , std::size_t )`
    * `( const wchar_t * , std::size_t )`
    * `( const char8_t * , std::size_t )` (since C++20)
    * `( const char16_t * , std::size_t )`
    * `( const char32_t * , std::size_t )`

* Literal operators template
```
template<char...>
double operator ""_x();
```
  * non-type template parameter of class type (string literal operator template)
```
struct A { constexpr A(const char *); };

template<A a>
A operator ""_a();
```

## Example

```c++
#include <iostream>
#include <iomanip>
​
class Value
{
public:
    int GetValue() const
    {
        return value;
    }
​
protected:
    explicit Value(int v)
        : value{ v }
    {}
    
    int value;
};
​
class Hour : public Value
{
public:
    Hour()
        : Hour{ 0 }
    {}
​
    explicit Hour(int h)
        : Value{ h }
    {}
​
};
​
class Minute : public Value
{
public:
    Minute()
        : Minute { 0 }
    {}
​
    explicit Minute(int m)
        : Value{ m }
    {}
};
​
class Second : public Value
{
public:
    Second()
        : Second{ 0 }
    {}
​
    explicit Second(int s)
        : Value{ s }
    {}
​
};
​
class TimeSpan : private Value
{
public:
    TimeSpan()
        : TimeSpan { 0 }
    {}
    
    explicit TimeSpan(const Hour& h)
        : TimeSpan { h.GetValue() * SECONDS_PER_HOUR }
    {}
    
    explicit TimeSpan(const Minute& m)
        : TimeSpan { m.GetValue() * SECONDS_PER_MINUTE }
    {}
​
    explicit TimeSpan(const Second& m)
        : TimeSpan { m.GetValue() }
    {}
​
    TimeSpan(const Hour& h, const Minute& m = Minute(0), const Second& s = Second(0))
        : TimeSpan { h.GetValue() * SECONDS_PER_HOUR + m.GetValue() * SECONDS_PER_MINUTE + s.GetValue() }
    {}
​
private:
    TimeSpan(int v)
        : Value{ v }
    {}
    
public:
    int GetTotalSeconds() const
    {
        return GetValue();
    }
    
    void PrintString() const
    {
        int h = GetValue() / SECONDS_PER_HOUR;
        int m = ( GetValue() % SECONDS_PER_HOUR ) / SECONDS_PER_MINUTE;
        int s = GetValue() % SECONDS_PER_MINUTE;
        std::cout << std::setw(4)
                  << std::setfill(' ')
                  << h
                  << ":"
                  << std::setw(2)
                  << std::setfill('0')
                  << m
                  << ":"
                  << std::setw(2)
                  << std::setfill('0')
                  << s
                  << std::endl;
    }
private:
    static constexpr int MINUTES_PER_HOUR = 60;
    static constexpr int SECONDS_PER_MINUTE = 60;
    static constexpr int SECONDS_PER_HOUR = MINUTES_PER_HOUR * SECONDS_PER_MINUTE;
​
};
​
Hour operator""_hr(unsigned long long int v)
{
    return Hour { static_cast<int>( v ) };
}
​
Minute operator""_min(unsigned long long int v)
{
    return Minute { static_cast<int>( v ) };
}
​
Second operator""_sec(unsigned long long int v)
{
    return Second { static_cast<int>( v ) };
}
​
int main()
{
    TimeSpan t1 = TimeSpan(3_hr, 2_min, 12_sec);
    std::cout << "Total Seconds: " << t1.GetTotalSeconds() << " seconds" << std::endl;
    t1.PrintString();
​
    TimeSpan t2 = TimeSpan(4_min);
    std::cout << "Total Seconds: " << t2.GetTotalSeconds() << " seconds" << std::endl;
    t2.PrintString();
​
    return 0;
}
```
