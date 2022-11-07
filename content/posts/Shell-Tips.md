---
title: "Shell Tips"
date: 2022-11-07T10:14:38+08:00
draft: false
---

記錄一些最近寫 Shell 用到的語法

# `shebang`

相關定義可以參考 [維基百科](https://zh.wikipedia.org/zh-tw/Shebang)

shebang 必須寫在 shell 的第一行，用來指示這個腳本使用的直譯器。

```shell=
#! /bin/bash

echo "SHELL = $SHELL"
echo "MY SHELL = $(ps -o comm -p $$ | awk 'NR==2 { print $1}')"
```

雖然可以用環境變數 `SHELL` 取得使用的 Shell 不過並不是很正確。所以需要用其他命令取得正確的 Shell。

在我的電腦上印出的是使用者預設的 shell 而不是 shebang 指定的 shell。使用 ps 才能拿到正確的 shell。

```
SHELL = /bin/zsh
MY SHELL = /bin/bash
```

# 使用者輸入

```shell=
echo "What's your name?"
read varname
echo "Hello $varname"
```

畫面會輸出一個等待輸入的提示，等待使用者輸入。

```
What's your name?
☐
```

等到輸入字串並按下 Enter 送出之後，變數的值就被設定為使用者所輸入的字串 （不包含 Enter）

```
What's your name?
Caesar
Hello Caesar
```

## 有用的參數

我們可以在 `read` 加上 `-p` 表示 `read` 要顯示的提示字串，就不需要用 `echo`。
也可以加上 `r` 指定不將反斜線視為跳脫字元。

```shell=
read -rp "What's your name? " varname
echo "Hello $varname"
```

需要注意的是，使用 `-p` 時的提示字串跟輸入游標沒有換行，需要自行加上空格排版，

```
What's your name? ☐
```

如果要用密碼輸入的話可以用 `-s` 來隱藏輸入。
因為 `-s` 會將送出的 Enter 也隱藏，所以顯示時可以加上一個空行來排版。

```shell=
read -rp "username? " username
read -srp "password? " password
echo ""
echo "Hello $username"
```

如果要實作 "press any key to continue" 可以用以下的語法。
使用 `-n 1` 來指定只要讀取 1 個字元。

```shell=
read -rp "username? " username
read -n 1 -srp "press any key to continue" key
echo ""
echo "Hello $username"
```

同樣的我們也可以用這個方法來實作選項。

```shell=
read -rp "username? " username
read -n 1 -rp "Are you $username (y/n)? " key
echo ""
if [ "$key" = "y" ]
then
    echo "Hello $username"
fi
```

# Color

Shell 輸出的時候可以加上控制碼改變文字或是背景的顏色，
我們在寫一些較長的腳本會希望輸出的地方能有色彩變化，
這樣在閱讀的時候比較容易找到重要的地方。

色碼的顏色文字跟背景的顏色可以分別設定。

## 控制碼

控制碼的格式為 `\033[xxm` 其中的 xx 就是顏色代碼。
使用的時候可以用 `echo -e` 指定後面的文字帶有控制碼。
另外，要注意的是結束的時候需要用 `\033[0m` 這個特殊的控制碼 (RESET) 將所有格式清空。
否則格式會影響到後面的輸出。

```shell=
echo -e "\033[31mhello\033[0m world"
```

以上代碼就會顯示出紅色的 hello 而 world 則是顯示預設的文字顏色。

## 前景 foreground

前景色一共有 16 色

- `\033[30m`: 黑色 (Black)
- `\033[31m`: 紅色 (Red)
- `\033[32m`: 綠色 (Green)
- `\033[33m`: 黃色 (Yellow)
- `\033[34m`: 藍色 (Blue)
- `\033[35m`: 洋紅色 (Magenta)
- `\033[36m`: 青色 (Cyan)
- `\033[37m`: 白色 (White)
- `\033[1;30m` (or `\033[90m`): 亮黑色 (Bright Black / Gray)
- `\033[1;31m` (or `\033[91m`): 亮紅色 (Bright Red)
- `\033[1;32m` (or `\033[92m`): 亮綠色 (Bright Green)
- `\033[1;33m` (or `\033[93m`): 亮黃色 (Bright Yellow)
- `\033[1;34m` (or `\033[94m`): 亮藍色 (Bright Blue)
- `\033[1;35m` (or `\033[95m`): 亮洋紅色 (Bright Magenta)
- `\033[1;36m` (or `\033[96m`): 亮青色 (Bright Cyan)
- `\033[1;37m` (or `\033[97m`): 亮白色 (Bright White)

## 背景 background

背景色一共有 16 色，可以用分號分隔就跟前景色一起使用。

- `\033[40m`: 黑色 (Black)
- `\033[41m`: 紅色 (Red)
- `\033[42m`: 綠色 (Green)
- `\033[43m`: 黃色 (Yellow)
- `\033[44m`: 藍色 (Blue)
- `\033[45m`: 洋紅色 (Magenta)
- `\033[46m`: 青色 (Cyan)
- `\033[47m`: 白色 (White)
- `\033[1;40m` (or `\033[100m`): 亮黑色 (Bright Black / Gray)
- `\033[1;41m` (or `\033[101m`): 亮紅色 (Bright Red)
- `\033[1;42m` (or `\033[102m`): 亮綠色 (Bright Green)
- `\033[1;43m` (or `\033[103m`): 亮黃色 (Bright Yellow)
- `\033[1;44m` (or `\033[104m`): 亮藍色 (Bright Blue)
- `\033[1;45m` (or `\033[105m`): 亮洋紅色 (Bright Magenta)
- `\033[1;46m` (or `\033[106m`): 亮青色 (Bright Cyan)
- `\033[1;47m` (or `\033[107m`): 亮白色 (Bright White)

## 其他控制符號

- `\033[0m`: 重置 (Reset)
- `\033[1m`: 粗體 (Bold)
- `\033[4m`: 底線 (Underline)
- `\033[7m`: 反轉前景、背景色 (Reverse)

另外也可以用來控制游標位置，做到類似進度條的顯示。
細節請參考[參考資料](https://www.lihaoyi.com/post/BuildyourownCommandLinewithANSIescapecodes.html)。
