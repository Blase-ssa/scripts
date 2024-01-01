Set fso = CreateObject("Scripting.FileSystemObject")		'объект файловой системы для удаления и копирования файлов
Set objNetwork = WScript.CreateObject("WScript.Network")	'объект для монтирования и отмонтирования дисков
set shell = WScript.CreateObject("WScript.Shell")			'объект для доступа к переменным среды окружения

'удаление сетевых дисков
On Error Resume Next
objNetwork.RemoveNetworkDrive "K:"
objNetwork.RemoveNetworkDrive "L:"
objNetwork.RemoveNetworkDrive "Q:"
objNetwork.RemoveNetworkDrive "R:"
objNetwork.RemoveNetworkDrive "M:"
objNetwork.RemoveNetworkDrive "N:"
objNetwork.RemoveNetworkDrive "O:"
objNetwork.RemoveNetworkDrive "P:"
WScript.Sleep 100

' выясняем адрес папки с виндой
AppData = shell.ExpandEnvironmentStrings("%AppData%")

'Удаление файлов (не обязательно, так как копирование с заменой)
Err.Clear
fso.DeleteFile AppData & "1c\1cestart\ibases.v8i", 1
fso.DeleteFile AppData & "1c\1cestart\1cestart.cfg", 1
WScript.Sleep 100

'Копирование  файлов
fso.CopyFile "D:\Service\1cProfile\1clogon_prof\ibases.v8i", AppData & "1c\1cestart\", 1
fso.CopyFile "D:\Service\1cProfile\1clogon_prof\1cestart.cfg", AppData & "1c\1cestart\", 1
WScript.Sleep 100

'монтирование сетевых дисков
objNetwork.MapNetworkDrive "K:", "\\HELLGATE\1C-DataBase", False
objNetwork.MapNetworkDrive "L:", "\\HELLGATE\PublicDocuments", False