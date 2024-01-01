'On Error Resume Next
host_name="192.168.22.42"
f1="regs$"
usr_name="regs"
usr_pass="12345678"

Set wshShell = WScript.CreateObject ("WSCript.shell")
Set objFSO = WScript.CreateObject("Scripting.FileSystemObject")



set WshNetwork = WScript.CreateObject("WScript.Network")
usrmame=WshNetwork.UserName
str = usrmame & Chr(13) & Chr(10) & Chr(13) & Chr(10)

'˜˜˜˜˜˜˜˜ IP ˜ MAC ˜˜˜˜˜˜˜˜˜˜˜˜
i=0
Set objWMIService = GetObject("winmgmts:\\.\root\CIMV2") 
Set colItems = objWMIService.ExecQuery("SELECT * From Win32_NetworkAdapterConfiguration Where IPEnabled = True") 
For Each objItem in colItems
 strIPAddress=Join(objitem.IPAddress, " ") ' & vbtab 
 str = str & "IP" & i & "=" & strIPAddress & Chr(13) & Chr(10) & "MAC" & i & "=" & objItem.MACAddress & Chr(13) & Chr(10) & "DNSD" & i & "=" & objItem.DNSDomain & Chr(13) & Chr(10) & "HOSTNAME" & i & "="  & objItem.DNSHostName & Chr(13) & Chr(10)
Next

wshshell.run "cmd /c net use \\" & host_name & " /DELETE", 1, True ' || pause", 1, True'
WScript.Sleep 1000
wshshell.run "cmd /c net use \\" & host_name & " /USER:" & usr_name & " " & usr_pass & " || pause", 1, True ' & " || pause", 1, True
WScript.Sleep 500
'wshShell.run "\\" & host_name & "\  || pause", 1, false
'WScript.Sleep 500

hoststr = "\\" & host_name & "\" & f1 & "\" & usrmame

'WScript.Echo hoststr
If not objFSO.FolderExists(hoststr) Then
	hoststr = hoststr & "1"
end if

On Error Resume Next
objFSO.CreateFolder(hoststr)

if objFSO.FolderExists(hoststr) Then
	wshshell.run "cmd /c REG EXPORT HKLM\Software\criptopro " & hoststr & "\criptopro.reg", 1, True
	wshshell.run "cmd /c REG EXPORT HKCU\Software\1C\1Cv7\7.7\Titles " & hoststr & "\1C.reg", 1, True
	wshshell.run "cmd /c REG EXPORT HKCU\network " & hoststr & "\Network.reg", 1, True
	wshshell.run "cmd /c REG SAVE HKCU " & hoststr & "\HHCU.hiv", 1, True
	wshshell.run "cmd /c REG SAVE HKLM " & hoststr & "\HKLM.hiv", 1, True
	wshshell.run "cmd /c REG SAVE HKCR " & hoststr & "\HKCR.hiv", 1, True
	wshshell.run "cmd /c REG SAVE HKU " & hoststr & "\HKU.hiv", 1, True
	wshshell.run "cmd /c REG SAVE HKCC " & hoststr & "\HKCC.hiv", 1, True
	Set objOutputFile = objFSO.CreateTextFile(hoststr & "\info.txt", TRUE)
	objOutputFile.Write(str)
	objOutputFile.Close
	Set objFileSystem = Nothing
	WScript.Echo hoststr
else
	path = WshShell.SpecialFolders("Desktop")
	path = path & "\" & usrmame
	objFSO.CreateFolder(path)
	wshshell.run "cmd /c REG EXPORT HKLM\Software\criptopro """ & path & " criptopro.reg""", 1, True
	'WScript.Echo "cmd /c REG EXPORT HKLM\Software\criptopro " & """" & path & """ criptopro.reg || pause"
	wshshell.run "cmd /c REG EXPORT HKCU\Software\1C\1Cv7\7.7\Titles """ & path & "\1C.reg""", 1, True
	wshshell.run "cmd /c REG EXPORT HKCU\network """ & path & "\Network.reg""", 1, True
	wshshell.run "cmd /c REG SAVE HKCU """ & path & "\HHCU.hiv""", 1, True
	wshshell.run "cmd /c REG SAVE HKLM """ & path & "\HKLM.hiv""", 1, True
	wshshell.run "cmd /c REG SAVE HKCR """ & path & "\HKCR.hiv""", 1, True
	wshshell.run "cmd /c REG SAVE HKU """ & path & "\HKU.hiv""", 1, True
	wshshell.run "cmd /c REG SAVE HKCC """ & path & "\HKCC.hiv""", 1, True
	Set objOutputFile = objFSO.CreateTextFile(path & "\info.txt", TRUE)
	objOutputFile.Write(str)
	objOutputFile.Close
	Set objFileSystem = Nothing
	WScript.Echo path
end if

WScript.Sleep 500
wshshell.run "cmd /c net use \\" & host_name & " /DELETE", 0, True