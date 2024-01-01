strComputer = "." 
Set objWMIService = GetObject("winmgmts:\\" _
    & strComputer & "\root\CIMV2") 
Set colItems = objWMIService.ExecQuery( _
    "SELECT * FROM Win32_NetworkAdapterConfiguration",,48) 
For Each objItem in colItems 
  Wscript.Echo "MACAddress: " & objItem.MACAddress

Next