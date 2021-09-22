---
title: "[Unity] 存取修飾詞 (Access Modifier) 與 Special folders & Assembly definition files"
date: 2018-11-12T01:50:00+08:00
tags: ["Unity", "C#"]
draft: true
---

存取修飾詞 Access Modifier

C# 的存取修飾詞有以下六種

public - 所有人都可以存取
protected - 只有所在類別以及他的的衍生類別可以存取
private - 只有所在類別可以存取
internal - 只有在相同 assembly 的類別可以存取
protected internal - 只有在相同 assembly 的類別或是所在類別以及他的的衍生類別可以存取 (也就是 protected OR internal)
private protected (C# 7.2) - 只有在相同 assembly 的類別以及所在類別以及他的的衍生類別可以存取 (也就是 protected AND internal)

從這張簡圖就很容易了解不同修飾詞的範圍


Type 只能宣告為 public 或 internal，Type Member 可以用所有的存取修飾詞宣告。

Default Access Modifier

預設值總是可見度最低的存取修飾詞。Type 為 internal，Type Member 為 private。


	預設的存取修飾詞	可用的存取修飾詞
namespace level
enum	internal	public, internal
interface	internal	public, internal
class	internal	public, internal
struct	internal	public, internal
delegate	internal	public, internal
type level
enum	private	public, protected, internal, private, protected internal, private protected
interface	private	public, protected, internal, private, protected internal, private protected
class	private	public, protected, internal, private, protected internal, private protected
struct	private	public, protected, internal, private, protected internal, private protected
delegate	private	public, protected, internal, private, protected internal, private protected
enum value	public	public
interface member	public	public
class member	private	public, protected, internal, private, protected internal, private protected
struct member	private	public, internal, private

以軟體設計的原則，應該讓類別、變數的可見性最小化。也就是說不需要公開的類別就不應該設為 public。

如果是開發共用的函式庫，我們希望讓程式碼被其他專案重複使用時，我們通常會把共用的函式庫放在獨立的資料夾與命名空間內。

另外也可以用獨立的儲存庫來存放，並且用 submodule 的方式加入到我們的專案中。

在 Unity 中，除了位於特殊資料夾以外的所有檔案會被放在遊戲專案中，為了降低程式間的耦合，以及避免在開發階段中意外將遊戲的功能寫到共用的函式庫的問題，我們可以利用一些 Unity 的機制來達成。

Special folders

根據 Unity 的說明，依據檔案所在的資料夾不同，script 會被分配到不同的專案中。也會有不同的編譯順序。根據官方說明，最多會分成四個專案編譯：

Phase 1: 在 Standard Assets、Pro Standard Assets 以及 Plugins 中非 Editor 資料夾的程式碼
Phase 2: 在 Standard Assets、Pro Standard Assets 以及 Plugins 中 Editor 資料夾的程式碼
Phase 3: 在 Standard Assets、Pro Standard Assets 以及 Plugins 以外非 Editor 資料夾的程式碼
Phase 4: 在 Standard Assets、Pro Standard Assets 以及 Plugins 以外的 Editor 資料夾的程式碼

Ref. Special folders and script compilation order

如果你使用 Visual Studio for Mac 開啟 Solution 只看到一個專案，你可以在 Solution 上按右鍵 -> 顯示選項 -> 顯示 Unity 專案總管，取消勾選後就會看到實際的專案。

實際上檢查各專案的參考設定可以得到底下的相依圖。

了解了這些細節，我們有了以下的設計：

遊戲專案相依於第三方專案（Ex. Asset Store 買來的插件）
當第三方插件放在 Assets 內，而不是 Plugins 內，就會讓遊戲專案可以存取到第三方插件的 internal 成員，這通常會破壞了第三方插件想要對外隱藏的資訊。
要達成這個目標，需要將所有的第三方插件移動到 Plugins 資料夾內。
部分第三方插件並沒有這樣設計，而且移動資料夾會造成之後更新維護的困擾。
這部分通常沒有大問題，畢竟我們不太會去修改第三方插件的內容。
在 Unity 2017.3 之後可以用 Assembly definition files 來解決 （稍後提到）。
在 Unity 2017.2 以前還是先保留在第三方插件原始的位置，使用上請注意不要誤用到 internal 的成員。
對於跨專案共用的函式庫
在 Unity 2017.2 以前可以將共用的函式庫放在 Plugins 之中，並且用 submodule 放到獨立的儲存庫。
如果將共用的函式庫放在  Plugins 以外，如此一來共用函式庫的內容就會跟遊戲專案在同一個 Assembly 之中。如果在新增或修改程式時沒有注意到，很容易在共用函式庫中呼叫遊戲專案的程式，造成其他用到此共用函式庫的專案編譯失敗。放在 Plugins 可以讓這個情形在編譯時就發生錯誤，避免在其他專案更新時才發現錯誤。
在 Unity 2017.3 之後可以用 Assembly definition files 來放到 Plugins 以外的資料夾，並且用 submodule 放到獨立的儲存庫。




Assembly definition files

從 Unity 2017.3 開始，我們可以針對不同的資料夾指定要編譯到獨立的專案中，並且設定彼此之間的相依關係。如此一來，就可以把第三方插件放在各自的 Assembly 之中，避免彼此影響，也不需要改變現有資料夾架構，只需要加入一個定義檔即可。

使用時只要在資料夾上按右鍵，選擇  Assets > Create > Assembly Definition 就會新增一個定義檔。然後在 Inspector 上將名稱與相依的 Assembly 設定好，在這個資料夾內的 Script 就會被分配到你指定名稱的專案中。你可以開啟 Visual Studio for Mac 確認。

Editor 似乎不會自動建立到 Xxx.Editor 專案中，所以需要同時加上 Editor 的 Assembly Definition File。

Ref. Script compilation and assembly definition files

另外使用 Assembly Definition File 額外帶來的好處還有。各別專案變小之後，當專案內的檔案有變動時，不需要重新編譯整個 Assembly-CSharp 。所以也可以提升編譯的速度。
