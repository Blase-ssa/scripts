l0 = "AutoUpdateDisable=0"
l1 = "SilentAutoUpdateEnable=1"
l2 = "SilentAutoUpdateServerDomain=wsus.it.cts.ru"
l3 = "SilentAutoUpdateVerboseLogging=1"

On Error Resume Next
Set objArgs = WScript.Arguments
' выясняем адрес папки с виндой
set shell = WScript.CreateObject("WScript.Shell")
windowsdir = shell.ExpandEnvironmentStrings("%windir%")
'MsgBox(windowsdir)

' выясняем разрядность винды
if right(shell.environment("system").item("processor_architecture"), 2) = "64" then
	Flash = windowsdir & "\SysWOW64\Macromed\Flash\" 'msgbox "64 bit"
else
	Flash = windowsdir & "\System32\Macromed\Flash\"'msgbox "32 bit"
end if

'msgbox (Flash)

' удаляем файл, а так же проверка привилегий
'shell.run "cmd /c notepad " & Flash, 0, True
Set fso = CreateObject("Scripting.FileSystemObject")
Err.Clear
fso.DeleteFile Flash & "mms.cfg", 1
'fso.DeleteFile "1.txt", 1
'Flash="1.txt"
'msgbox( objArgs(0))

' если не хватило прав на удаление, то перезапускаем скрипт с повышением привилегий
if Err.Number > 0 Then
	'msgbox "permission denied!"
	if objArg.count = 0 then
		Set objShell = CreateObject("Shell.Application")
		objShell.ShellExecute "wscript.exe", Chr(34) & _
		WScript.ScriptFullName & Chr(34) & " uac", "", "runas", 1
		wscript.quit
	else ' если скрипт повторно пытается повысить себе привилегии, гасим его
		'msgbox( objArgs(0))
		msgbox "Interrupt execution"
		wscript.quit 
		msgbox "Interruption Fail!!!"
	end if
end if

' создание нового файла
'msgbox "CreateTextFile"
set mmscfgstream = fso.CreateTextFile(Flash & "mms.cfg", true)
mmscfgstream.WriteLine(l0)
mmscfgstream.WriteLine(l1)
mmscfgstream.WriteLine(l2)
mmscfgstream.WriteLine(l3)
mmscfgstream.Close

WScript.Sleep 1000
' запуск обновления принудительно
shell.run "cmd /c " & Flash &  "FlashPlayerUpdateService.exe", 0, True
WScript.Sleep 5000
' повторный запуск
shell.run "cmd /c " & Flash & "FlashPlayerUpdateService.exe", 0, False