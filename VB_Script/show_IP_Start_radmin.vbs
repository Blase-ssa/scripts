'добываем IP и MAC пользователя
i=0
Set objWMIService = GetObject("winmgmts:\\.\root\CIMV2") 
Set colItems = objWMIService.ExecQuery("SELECT * From Win32_NetworkAdapterConfiguration Where IPEnabled = True") 
For Each objItem in colItems
 strIPAddress=Join(objitem.IPAddress, " ") ' & vbtab 
 str = str & "IP " & i & " = " & strIPAddress & Chr(13) & Chr(10)
 i=i+1
Next
Set wshShell = WScript.CreateObject ("WSCript.shell")
wshshell.run "C:\WINDOWS\system32\r_server.exe /start", 0, false
set wshshell = nothing
Wscript.Echo "Radmin запущен, вашь IP адрес:" & Chr(13) & Chr(10) & str