---
title: "[Unity] 忽略警告訊息"
date: 2018-11-07T15:49:00+08:00
tags: ["Unity", "C#"]
draft: true
---

在 Unity 中如果有用到其他 Plugins 經常會發現許多來自這些 Plugins 的 Warning
如果不處理的話，這些訊息可能會淹沒了專案中需要注意的警告訊息

底下是來自目前專案的警告訊息

Unity 看到的警告訊息大約 300個

從 Visual Studio for Mac 看到的警告訊息超過 2000個

NOTE: Unity 跟 Visual Studio for Mac 的警告訊息數量不同，最好兩個都檢查

雖然理論上警告訊息必須要修正，But 專案進行中總是有很多無法掌握的情形，
以下介紹目前處理專案中難以修改的警告訊息的方式

Plugins' warning

但是對於第三方的 Plugins 我們可以先用 #pragma warning 關閉
關閉的方式使用 disable 關閉並在使用後用 restore 開啟顯示警告

底下的例子來自 MSDN

[code language="csharp"]
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
[/code]

Ref. MSDN: #pragma warning (C# Reference)
Ref. MSDN: Compiler Warning (level 4) CS0649

可以在發生警告前一行加上 #pragma warning disable warning-list，並且在發生警告後一行加上 #pragma warning restore warning-list 開啟。
一個檔案的警告太多也可以在檔案開頭與結尾分別加上關閉與還原。

NOTE: 這樣的關閉方式，一但更新 Plugins 的時候必須要重新處理一次

Project's warning

相較於 Plugins 的警告訊息，自己專案的警告訊息是比較需要處理的。
不過 Unity 本身的機制會造成許多警告訊息不斷出現，會影響到重要的警告被淹沒在大量警告訊息中
底下的範例示範在 Unity 中引發最常見的警告 CS0649 的方式：


[code language="csharp"]
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
[/code]

以上的情況很常發生，通常發生在我們要在 inspector 上設定值或是參考到場景上的 GameObject 的變數上且沒有給初始值的情況。
解決方法可以在宣告上加上初始值，雖然大部分這個初始值不會發生作用


[code language="csharp"][SerializeField] private int warning0649 = 0;[/code]

對於開發中的專案，要修復可能必須花上很多時間
所以我們可以採用另一種比較暴力的處理方式
使用 mcs.rsp Ref. Unity Documentation: Global custom #defines

詳細的使用參考可以用 mcs -help 指令查詢

我們用到的是其中的 nowarn 參數來將特定的警告關閉
以下是我們的 mcs.rsp 的內容，檔案需要放在 Assets/mcs.rsp


[code language="text"]
-nowarn:0649
-nowarn:1635
[/code]

在這裡我們關閉了 CS0649 這個常見的警告訊息，另外也關閉了 CS1635 這個新的警告訊息！
這個警告訊息是說，我們在全域關閉了某個警告訊息，如果有人用 #pragma warning restore 重新開啟警告時就會有這個警告
因此我們也需要忽略這個警告
Ref. MSDN: Compiler Warning (level 1) CS1635

Conclusion

不論是用 #pragma warning 或是 mcs.rsp 來忽略警告訊息都不是很推薦的作法
最好還是將警告都處理掉，
不過對於外部的 Plugins 可以稍微放寬一點，容忍警告的發生，但是避免警告影響到專案本身
將 Plugins 的警告都隱藏起來，只要關注在專案本身
對於現有專案，考量到修改的成本，使用全域的 mcs.rsp 只是折衷的手段，
最終還是需要花費時間回頭處理累積的技術債
