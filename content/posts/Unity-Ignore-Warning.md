---
title: "[Unity] 忽略警告訊息"
date: 2018-11-07T15:49:00+08:00
tags: ["Unity", "C#"]
---

在 Unity 中如果有用到其他 Plugins 經常會發現許多來自這些 Plugins 的 Warning。如果不處理的話，這些訊息可能會淹沒了專案中真正需要注意的警告訊息。

底下是來自我們目前專案的警告訊息：

Unity 看到的警告訊息大約 300個
![Unity 看到的警告訊息大約 300個](/Blog/images/Unity-Ignore-Warning/Warning-1.png)

從 Visual Studio for Mac 看到的警告訊息超過 2000個
![從 Visual Studio for Mac 看到的警告訊息超過 2000個](/Blog/images/Unity-Ignore-Warning/Warning-2.png)


**NOTE**: Unity 跟 Visual Studio for Mac 的警告訊息數量不同，最好兩個都檢查


雖然理論上警告訊息都必須要修正，但是專案進行中總是有很多無法掌握的情形，
以下介紹我在目前處理的專案中，遇到難以修改的警告訊息的解決方式：


## Plugins' warning

對於第三方的 Plugins 我們可以先用 `#pragma warning` 命令來暫時關閉警告訊息。

關閉的方式使用 `#pragma warning disable` 暫時關閉，並在使用後用 `#pragma warning restore` 開啟警告。

通常會在發生警告前一行加上 `#pragma warning disable *warning-list*`，並且在發生警告後一行加上 `#pragma warning restore *warning-list*` 重新開啟警告。

一般來說，建議將關閉警告與開啟警告的範圍越小越好，避免意外隱藏其他有意義的警告訊息。

如果檔案裡的警告太多，也可以在檔案開頭與結尾分別加上關閉與還原檔案內所有警告訊息。

**NOTE**: 這樣的關閉方式，一但更新 Plugins 的時候可能要重新處理一次。


底下的例子來自 MSDN

```csharp
// CS0649.cs
// compile with: /W:4
using System.Collections;

class MyClass
{
#pragma warning disable 0649
   Hashtable table;  // CS0649
#pragma warning restore 0649
   // You may have intended to initialize the variable to null
   // Hashtable table = null;

   // Or you may have meant to create an object here
   // Hashtable table = new Hashtable();

   public void Func(object o, string p)
   {
      // Or here
      // table = new Hashtable();
      table[p] = o;
   }

   public static void Main()
   {
   }
}
```

- Ref. [MSDN: #pragma warning (C# Reference)](https://docs.microsoft.com/en-us/dotnet/csharp/language-reference/preprocessor-directives/preprocessor-pragma-warning)

- Ref. [MSDN: Compiler Warning (level 4) CS0649](https://docs.microsoft.com/en-us/dotnet/csharp/misc/cs0649)


## Project's warning

相較於 Plugins 的警告訊息，自己專案的警告訊息是比較需要處理的。

不過 Unity 本身的機制會造成許多警告訊息不斷出現，會影響到重要的警告被淹沒在大量警告訊息中

底下的範例示範在 Unity 中引發最常見的警告 CS0649 的方式：

```csharp
using UnityEngine

public class ExampleScript : MonoBehaviour
{
    private int noWarning;

    // Warning CS0649: Field is never assigned to, and will always have its default value null
    [SerializeField] private int warning0649;

    private void Awake()
    {
        noWarning = warning0649;
    }
}
```

以上的情況很常發生，通常發生在我們要在 inspector 上設定值或是參考到場景上的 GameObject 的變數上且沒有給初始值的情況。

簡單的解決方法可以在宣告的時候加上初始值，雖然大部分情況這個初始值不會發生作用。

```csharp
[SerializeField] private int warning0649 = 0;
```


對於開發中的專案，要修復所有警告可能需要花上很多時間，我們可以採用另一種比較暴力的處理方式。

使用 `mcs.rsp` 檔案來設定專案中要忽略的警告。
詳細的使用方式可以用 `mcs -help` 指令查詢。

- Ref. [Unity Documentation: Global custom #defines](https://docs.microsoft.com/en-us/dotnet/csharp/misc/cs0649)

我們會用到其中的 `nowarn` 參數來將特定的警告關閉。
因為 `mcs.rsp` 是全專案的隱藏，可能會誤關到真正會發生問題的警告，所以使用上必須小心選擇要關閉的警告。


我們的 `mcs.rsp` 的內容只有簡單地忽略幾個 Unity 常見的警告訊息，檔案需要放在 `Assets/mcs.rsp` 路徑下。

```text
-nowarn:0649
-nowarn:1635
```

在這裡我們關閉了 CS0649 這個常見的警告訊息，另外也關閉了 CS1635 這個警告訊息。
CS1635 是當我們在全域關閉了某個警告訊息，如果有人用 `#pragma warning restore` 重新開啟這個警告的時後就會有這個警告。因此我們也需要忽略這個警告。

- Ref. [MSDN: Compiler Warning (level 1) CS1635](https://docs.microsoft.com/en-us/dotnet/csharp/misc/cs0649)


## Conclusion

不論是用 `#pragma warning` 或是 `mcs.rsp` 來忽略警告訊息都不是很推薦的作法。

最好還是可以將所有警告都處理掉，
不過對於外部的 Plugins 可以稍微放寬一點，容忍警告的發生，但是要注意避免警告訊息影響到專案本身。
可以將 Plugins 的警告都隱藏起來，只要關注在專案本身的警告訊息即可。

對於現有專案，考量到修改的成本，使用全域的 `mcs.rsp` 是折衷的手段，
最終還是需要花費時間回頭處理累積的技術債。
