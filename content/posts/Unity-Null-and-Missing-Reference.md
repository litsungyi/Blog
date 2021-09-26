---
title: "Unity - Null & Missing Reference Validator"
date: 2019-12-06T03:41:00+08:00
tags: ["Unity", "C#"]
draft: true
---

## NotNullAttribute

在 Unity 中如果想要在編譯期增加驗證，確保 GameObject 必須要設定好參考，避免沒有設定好參考執行時出錯。我們可以用一個自訂的 `Attribute NotNullAttribute` 來標注需要檢查的成員。並且增加一個檢查函式來檢查參考是否為空。

```csharp
[AttributeUsage(AttributeTargets.Field)]
public class NotNullAttribute : Attribute
{
}
```

- 使用的方式只要在 GameObject 的成員加上 [Not Null] 即可

**注意！**

這個檢查，目前只適用在 GameObject 及其子類別的成員。至於其他 Reference Type 的成員（也就是 SerializeField 的成員）。因為 Unity 的 Serialization 機制所致， Reference Type 的成員不會是 null。所以 NotNull 的檢查永遠不會生效。

```csharp
public class TestMonoBehaviour : MonoBehaviour
{
    [NotNull, SerializeField]
    private GameObject notNullPrivateItem;
    
    [NotNull, SerializeField] private GameObject notNullPrivateItem_Null;
    [SerializeField] private GameObject privateItem;
    [SerializeField] private GameObject privateItem_Null;
    [NotNull] public GameObject notNullPublicItem;
    [NotNull] public GameObject notNullPublicItem_Null;
    public GameObject publicItem;
    public GameObject publicItem_Null;
}
```

## PostProcessBuild

另外我們需要一個 PostProcessBuild 來進行驗證，其中的 CheckAllEnabledScenes 跟 CheckAllPrefabs 用來從所有的 Scenes 以及 Prefabs 之中檢查所有的 Components。

```csharp
public static class ValidatorProcess
{
    [PostProcessBuild]
    public static void OnPostprocessBuild(BuildTarget target, string pathToBuiltProject)
    {
        var checkPassed = CheckAllEnabledScenes() & CheckAllPrefabs();
        if (!checkPassed)
        {
            throw new Exception("[*] Null or Missing Reference check failed!");
        }
    }
}
```

檢查 GameObject 時需要使用反射取得所有有 NotNullAttribute 的成員並檢查是否為 null

```csharp
private static bool IsNotNullValidationFailed(FieldInfo fieldInfo, object fieldValue)
{
    var attributes = fieldInfo.GetCustomAttributes(typeof(NotNullAttribute), false);
    if (attributes.Any())
    {
        if (fieldValue == null || fieldValue.Equals(null))
        {
            return true;
        }
    }
    
    return false;
}
```

## Source Code

- [測試程式碼](https://github.com/litsungyiAktsk/MissingReferenceValidator)
