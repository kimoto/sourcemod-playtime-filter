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

*システム設計
  少し複雑なのでシステム設計をメモしておきます

  初期化処理
  1. 起動時にMaxClient(defualt: 18)ぶんの要素を持つ配列を確保します
  2. すべてにINVALID_HANDLEを設定します

  プレイヤー接続時
  3. プレイヤー接続時に以下の処理を実行します
    4. client indexからSteamIdを取得します
    5. SteamIdからProfileIdを取得します(CSteam extensionを使います)
    6. client indexを元に、初期化で作成した配列の中の自分専用の領域に空のDataPackを作成します
      すでにDataPackがそこにあった場合は、他のスレッドにて現在取得処理中であるハズなので
      エラーとして終了します。"そのときそのクライアントはkickされます"(ここはまだ未実装)
    7. ProfileIdを元に、SteamStats APIに非同期でHTTP1.0/GET開始します(Socket extensionを使います)
    8. 非同期に受信したXMLデータをメモリ内に書き込み(蓄積)します
      初期化処理で作成したMaxClient分の配列の、現在対象となってるclientに対応する配列要素にDataPackオブジェクトがあるので、そこに受信したデータを追記していきます

      イメージ図(client indexの1が現在対象となってる場合の例、他に現在受信してるスレッドがない場合)
      ---------------
      buffers[0] = INVALID_HANDLE;
      buffers[1] = DataPack;
      buffers[2] = INVALID_HANDLE;
      ...
      buffers[17] = INVALID_HANDLE;
      ---------------
      当然非同期にこの処理は実行されるので、次のようになることも普通に起こりうる
      (すべてのclientに対するデータが受信中状態の例)
      ---------------
      buffers[0] = DataPack;
      buffers[1] = DataPack;
      buffers[2] = DataPack;
      ...
      buffers[17] = DataPack;
      ---------------
    9. 取得したXMLデータを解析しプレイ時間を取得します
    10. 解析したプレイ時間を元にcvarの設定と照合し、入場を許可出来ない場合はkickします
      cvarの設定というのは、playtime_filter_min_playtime, playtime_filter_max_playtime のことです
      "playtime_filter_enableが0になっている場合はkickされません"(ここはまだ未実装)
    11. 取得したXMLデータをメモリ上から解放し、INVALID_HANDLEを代入します
      DataPack配列の、現在対象となってるclient indexの要素をメモリから解放し
      そこにINVALID_HANDLEを代入しCloseHandleします

