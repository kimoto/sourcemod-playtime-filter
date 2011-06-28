playtime-filter Manual
Author: kimoto

*動作環境
  WindowsのListen Server + 1人でしか検証してません。
  あとまだあんまテストしてないので非同期関係のバグがありそうなので突然死する可能性や
  なんかトラブルの可能性もあります。

*インストール
  以下のファイルをインストールします。Linux環境ではdllがsoになります

  CSteam extension
  ./extensions/csteam.ext.dll
  ./scripting/include/csteam.inc

  Socket extension
  ./extensions/socket.ext.dll
  ./scripting/include/socket.inc

  ./plugins/playtime-filter.smx

*コマンドラインインターフェース
  playtime_filter_enable "1" 
    playtime_filterを有効化します
    1で有効化、0で無効化(デフォルト1)

    1に設定されている場合はユーザーが新規接続時にプレイ時間の検証を受けます
    0に設定されている場合はユーザーは自由に接続できます

    1に変更したとしてもすぐには検証処理は実行されません。ユーザーは次回接続時に検証処理を受けます

  playtime_filter_test_run
    現在の設定で、試験的にフィルタを実行してみることが出来ます
    現在ログイン中のユーザー全てに対して検証処理を実行します

  playtime_filter_min_playtime "100h"
  playtime_filter_max_playtime "300h"
    サーバーにログインすることを許可するプレイ時間の範囲をこの二つのコマンドを利用して設定します

    *たとえば200h未満のプレイヤーのみ許可したい場合は
    playtime_filter_min_playtime "0h"
    playtime_filter_max_playtime "199h 59m 59s"

    *200h以下のプレイヤーのみ許可したい場合は
    playtime_filter_min_playtime "0h"
    playtime_filter_max_playtime "200h"

    *1000h以上のプレイヤーのみ許可したい場合は
    playtime_filter_min_playtime "1000h"
    playtime_filter_max_playtime "9999h"

*設定ファイル
  設定ファイルは他のSourceMODプラグインと同様で、./cfg/sourcemod/playtime-filter.cfgにあります。
  設定できる項目、内容は先述のコマンドラインインターフェースと同じです。

