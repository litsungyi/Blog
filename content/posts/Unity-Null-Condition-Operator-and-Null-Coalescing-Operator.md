---
title: "Unity - 使用 Null Condition Operator & Null Coalescing Operator"
date: 2019-09-16T20:35:00+08:00
tags: ["Unity", "C#"]
---

**Null Conditional Operator** 跟 **Null Coalescing Operator** 都是 C# 6.0 的新語法，可以讓你寫出更加精簡而且可讀性佳的語法。但是在 Unity 中使用需要特別注意，在某些情況下，執行結果可能跟你想的不一樣。


## Null Condition Operator (`?.`) 

當 `?.` 的左側是 `null` 就不會執行右側的語法，如此就可以移除掉很多 `null` 檢查讓我們的程式更加簡潔好讀。

先看一下不使用 **Null Conditional Operator** 的情況：

```csharp
var text = string.Empty;
if (m_controller != null)
{
    if (m_controller.m_display != null)
    {
        if (m_controller.m_display.m_text != null)
        {
            text = m_controller.m_display.m_text.text;
        }
    }
}
```

如果使用 **Null Conditional Operator** 的話，可以改寫成以下的語法：

```csharp
var text = m_controller?.m_display?.m_text?.text;
if (text = null)
{
    text = string.Empty;
}
```

如果其中任何一部份回傳值為 `null`，text 最後的結果就是最後結果的預設值 (default)。對於參考型別來說就是 `null` 了，值型別就是 `0` 或 `false`。


## Null Coalescing Operator (`??`) 

同時我們也可以搭配 **Null Coalescing Operator** 寫出更精簡的敘述句。當 `??` 的左側執行的結果不是 `null` ，就回傳左側的結果，否則回傳右側的值。

我們可以將前面的句子再改寫成底下的敘述式：

```csharp
var text = m_controller?.m_display?.m_text.text ?? string.Empty;
```

## 小結

除了可讀性以外，另外一個好處則是 **Null Conditional Operator** 在多執行緒環境下可以安全的使用。

以第一個例子來說，如果我們在檢查完 m_controller 不是 `null` 之後，如果馬上被另外一個 thread 設為 `null`，那麼在接下來的 m_controller.m_display 仍然會拋出 `NullReferenceException`。**Null Conditional Operator** 則會由 compiler 使用額外的參考來避免例外發生。

總之，請盡量使用 **Null Conditional Operator** 跟 **Null Coalescing Operator** 取代傳統的巢狀 if 的 `null` 檢查。

- Ref. [[MSDN] Null-conditional operators ?. and ?[]](https://docs.microsoft.com/en-us/dotnet/csharp/language-reference/operators/member-access-operators#null-conditional-operators--and-)
- Ref. [[MSDN] ?? and ??= operators (C# reference)](https://docs.microsoft.com/en-us/dotnet/csharp/language-reference/operators/null-coalescing-operator)


## Working with Unity

雖然 **Null Conditional Operator** 跟 **Null Coalescing Operator** 很好用，但是在 Unity 卻有一個不容易發現的陷阱。雖然影響並沒有很大，但是會產生奇怪的錯誤訊息與行為可能會讓你十分困擾。

假設有這樣的程式碼，我們有一個 m_controller 繼承自 MonoBehaviour，並且有一個函式 DisableController 用來清除掉這個 m_controller。OnDestroy 則是用來保證 m_controller 能夠正確的被清除掉。

```csharp
public class TextInstance : MonoBehaviour
{
    public string text = "TEXT";
}

public class Test1 : MonoBehaviour
{
    [SerializeField] private TextInstance m_instance;

    private void UnsafeLogText()
    {
        Debug.Log(m_instance?.text ?? string.Empty);
    }

    private void UnsafeDestroy()
    {
        Destroy(m_instance.gameObject);
    }

    private void SafeLogText()
    {
        if (m_instance != null)
        {
            Debug.Log(m_instance.text ?? string.Empty);
        }
    }

    private void SafeDestroy()
    {
        if (m_instance != null)
        {
            Destroy(m_instance.gameObject);
        }
    }
}
```

但是這一段程式碼如果曾經呼叫過 `UnsafeDestroy` 或 `SafeDestroy` 的話，如果再次呼叫 `UnsafeLogText` 都會印出 TEXT。但是如果呼叫 `SafeLogText` 則不會印出任何東西。

如果在此時呼叫 `UnsafeDestroy`，就會看到輸出視窗印出錯誤訊息：

```text
MissingReferenceException: The object of type 'TextInstance' has been destroyed but you are still trying to access it.
Your script should either check if it is null or you should not destroy the object.
```

這個結果表示 Unity 在 Destroy 物件後的 `m_instance != null` 跟 `m_instance?.` 的行為並不一致，並且這個不一致的結果只在 Editor 上發生，實際裝置上並不會發生。

因此，如果是對於可能在執行期間刪除的 MonoBehaviour 物件，最好總是在 Destroy 之後將變數設為 `null`。如果外部可以拿到這個 MonoBehaviour 的參考時，你可能無法將所有的參考都設為 `null`，這時候最好避免用 Null Conditional Operator 做判斷。


### 發生原因

接下來要解釋一下為什麼會發生這個問題

UnityEditor 在物件消滅時並不會完全從記憶體中清除，因此在你不小心使用到已經消滅的物件時
UnityEditor 才有辦法提供足夠的資訊讓你除錯。Unity 是透過覆寫 UnityEngine.Object 的 `operator==` 讓已經消滅的物件跟 `null` 比較時返回 `true`。

不過因為 **Null Conditional Operator** 與 **Null Conditional Operator** 是 C# 語言層的語法，使用的是 `ReferenceEquals` 而不是 `operator==`。因此在 UnityEditor 中的判斷會失敗，而 `ReferenceEquals` 是 System.Object 的 static method 無法覆寫。

Unity 為了除錯的考量也不打算修改這個歧異的行為，所以在 Unity 使用 `?.` 或是 `??` 的時候需要特別注意。


### 建議

最後，這是建議的用法

- 如果不是繼承 UnityEngine.Object 的類別，使用 `?.` 或是 `??` 簡化程式碼完全不會有任何副作用，可以放心使用。
- 如果是繼承 UnityEngine.Object 的類別需要特別注意。
    - 如果可以確保呼叫的物件不會中途被 Destroy ，可以使用 `?.` 或是 `??` 簡化程式碼。
    - 如果物件的參考不會被外部取得。只要記得在 Destroy 時將自己設為 `null`，還是可以使用 `?.` 或是 `??` 簡化程式碼。
    - 否則，盡量使用 `if` 判定 `null`，以避免 Editor 與實機的不同。
