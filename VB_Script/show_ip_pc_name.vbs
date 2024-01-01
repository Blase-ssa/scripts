On Error Resume Next
'добываем IP и MAC пользовател€
i=0
Set objWMIService = GetObject("winmgmts:\\.\root\CIMV2") 
Set colItems = objWMIService.ExecQuery("SELECT * From Win32_NetworkAdapterConfiguration Where IPEnabled = True") 
For Each objItem in colItems
 GateWay = "" ' на случай если параметр пуст, очищаем от предыдущего значения
 strIPAddress = "" ' на случай если параметр пуст, очищаем от предыдущего значения
 strIPAddress = Join(objItem.IPAddress, " ") ' & vbtab 
 GateWay = Join(objItem.DefaultIPGateway, " ")
 strIP = strIP & objItem.Caption & Chr(13) & Chr(10) & vbtab & "IP " & i & " = " & strIPAddress & Chr(13) & Chr(10) & vbtab & "GateWay = " & GateWay & Chr(13) & Chr(10) '& vbtab
 i=i+1
 
Next
' имя машины
Set WshNetwork = CreateObject("WScript.Network")
ComputerName = WshNetwork.ComputerName

Wscript.Echo "PC" & vbtab & ComputerName & Chr(13) & Chr(10) & strIP