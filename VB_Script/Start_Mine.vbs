ethProxyDir = "C:\mine\eth-proxy\" ' ".\"
ethMinerDir = "C:\mine\ethminer-0.9.41-genoil-1.1.6-pre\" ' ".\"
farmRecheck = 200

ethProxy = "eth-proxy.exe"
ethMiner = "ethminer.exe"


cmdLine = " & SETX GPU_FORCE_64BIT_PTR 0" & _
" & SETX GPU_MAX_HEAP_SIZE 100" & _
" & SETX GPU_USE_SYNC_OBJECTS 1" & _
" & SETX GPU_MAX_ALLOC_PERCENT 100" & _
" & SET GPU_SINGLE_ALLOC_PERCENT 100"
minercmd = "--farm-recheck " & farmRecheck & " -G -F http://127.0.0.1:8080/der-m1 --cl-local-work 256 --cl-global-work 16384"

'Wscript.Echo cmdLine
'Wscript.Echo minercmd
'Wscript.Quit

Set wshShell = WScript.CreateObject ("WSCript.shell") ' запуск командной строки
Set objWMIService = GetObject("winmgmts:\\.\root\CIMV2") '
Set colItems = objWMIService.ExecQuery("SELECT * From Win32_NetworkAdapterConfiguration Where IPEnabled = True") '
Set WshNetwork = CreateObject("WScript.Network") ' получение имени компа

' запуск прокси
wshshell.run "cmd /K cd /D """ & ethProxyDir & """ & " & ethProxy, 1, False
WScript.Sleep(5000)
wshshell.run "cmd /K  cd /D """ & ethMinerDir & """ & " & cmdLine & " & " & ethMiner & minercmd, 1, False

On Error Resume Next
'добываем IP и MAC пользовател€
i=0
For Each objItem in colItems
 GateWay = "" ' на случай если параметр пуст, очищаем от предыдущего значения
 strIPAddress = "" ' на случай если параметр пуст, очищаем от предыдущего значения
 strIPAddress = Join(objItem.IPAddress, " ") ' & vbtab 
 GateWay = Join(objItem.DefaultIPGateway, " ")
 strIP = strIP & objItem.Caption & Chr(13) & Chr(10) & vbtab & "IP " & i & " = " & strIPAddress & Chr(13) & Chr(10) & vbtab & "GateWay = " & GateWay & Chr(13) & Chr(10) '& vbtab
 i=i+1
 
Next
' имя машины

ComputerName = WshNetwork.ComputerName

Wscript.Echo "PC" & vbtab & ComputerName & Chr(13) & Chr(10) & strIP