'On Error Resume Next
host_name="192.168.0.2"		' сервер
f1="regs$"					' папк
usr_name="regs"				' логин
usr_pass="12345678"			' пароль

Set wshShell = WScript.CreateObject ("WSCript.shell")
Set objFSO = WScript.CreateObject("Scripting.FileSystemObject")
set WshNetwork = WScript.CreateObject("WScript.Network")

' добываем имя пользователфя
usrmame=WshNetwork.UserName
str = usrmame & vbTab 

'добываем IP и MAC пользователя
i=0
Set objWMIService = GetObject("winmgmts:\\.\root\CIMV2") 
Set colItems = objWMIService.ExecQuery("SELECT * From Win32_NetworkAdapterConfiguration Where IPEnabled = True") 
For Each objItem in colItems
 strIPAddress=Join(objitem.IPAddress, " ") ' & vbtab 
 str = str & vbTab & strIPAddress & vbTab & objItem.MACAddress & vbTab & objItem.DNSDomain & vbTab & vbTab & objItem.DNSHostName & vbTab
Next

Err.Clear

' подключение к серверу
wshshell.run "cmd /c net use \\" & host_name & " /DELETE", 0, True ' || pause", 1, True'
WScript.Sleep 5000 ' не смотря на то что мы ожидаем окончание обработки предыдущей команды, требуется задержка прежде чем запускать следующую, по сколько фактически по завершениие команды, действие ещё не закончено
wshshell.run "cmd /c net use \\" & host_name & " /USER:" & usr_name & " " & usr_pass, 0, True ' & " || pause", 1, True'
WScript.Sleep 5000

If Err.Number <> 0 Then
	 Wscript.Quit
end if



' сохранение на сервер
hoststr = "\\" & host_name & "\" & f1
if objFSO.FolderExists(hoststr) Then
	Set objOutputFile = objFSO.CreateTextFile( hoststr & "\" & usrmame & "_MAC.txt", TRUE)
	objOutputFile.Write(str)
	objOutputFile.Close
	Set objFileSystem = Nothing
end if

WScript.Sleep 500
wshshell.run "cmd /c net use \\" & host_name & " /DELETE", 0, True
WScript.Sleep 500