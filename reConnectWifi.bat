@echo off

rem #############################
rem 管理者権限で実行すること
rem #############################


rem 文字コードをUTF-8にする。日本語文字化け対策。
chcp 65001

rem チェック時間間隔を設定する(sec)
set interval=60

rem インターフェース名。netsh interface show interfaceで接続確認したいInterface nameをセットする
set "interfaceName=Wi-Fi"

rem ログファイル名
set logFileName=reconnectWifi.log

rem カレントディレクトリをバッチファイルのあるディレクトリに変更する
cd /d "%~dp0"

rem スタート時刻をログに残しておく
echo %date% %time%,Start reConnectWifi %interfaceName%>> %logFileName%

rem 現在の状態を表示 
netsh interface show interface "%interfaceName%"

rem Connectedが見つからなければ未接続判定
:checking
echo [%date% %time%] Checking %interfaceName%...
netsh interface show interface %interfaceName% | find "Connect state:        Connected" > nul
if ERRORLEVEL 1 goto notconnection

rem Connectedでもpingが通らなければ未接続判定
for /f "usebackq tokens=*" %%a in (`ping google.com`) do (

  echo %date% %time%,%%a >> %logFileName%

  rem 文字列に対してfindコマンドを実行し，実行結果のエラーレベルを調べる
  echo %%a | find "could not find" >NUL
  if not ERRORLEVEL 1 (
    echo %date% %time%, google.com not found>> %logFileName%
    goto notconnection
  )
  echo %%a | find "要求がタイムアウトしました" >NUL
  if not ERRORLEVEL 1 (
    echo %date% %time%, Time out google.com access.>> %logFileName%
    goto notconnection
  )
)


echo [%date% %time%] %interfaceName% is connected.

rem 指定したインターバル毎にチェックする
timeout /t %interval% > nul
goto checking


rem 未接続時
:notconnection
echo [%date% %time%] %interfaceName% is not connected. try to reconnect.

rem ログに切断を検出した日時を保存
echo %date% %time%,disconnect! try to reconnect %interfaceName%>> %logFileName%

echo [%date% %time%] disable %interfaceName% 
netsh interface set interface "%interfaceName%" disable > nul
timeout /t 10 > nul
echo [%date% %time%] restart %interfaceName%.
netsh interface set interface "%interfaceName%" enable > nul
timeout /t 20
goto checking

pause
