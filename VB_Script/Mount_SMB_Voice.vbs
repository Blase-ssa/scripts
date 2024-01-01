' при ошибке ничего не говорим пользователю
On Error Resume Next

' получаем логин, формируем usr_name
set WshNetwork = WScript.CreateObject("WScript.Network")
usr_name = "User"
usr_pass = "Password"
server = "ServerName or IP"

'подключен ли сетевой диск (если нет тогда будет ошибка)
Err.Clear
WshNetwork.RemoveNetworkDrive "Z:"
if Err.Number <> 0 Then
	' подключаем диск
	WshNetwork.MapNetworkDrive "Y:", "\\" & server & "\smbroot$\Music", 0, usr_name, usr_pass
	WshNetwork.MapNetworkDrive "X:", "\\" & server & "\smbroot$\photo", 0, usr_name, usr_pass
	WshNetwork.MapNetworkDrive "W:", "\\" & server & "\smbroot$\rest", 0, usr_name, usr_pass
	WshNetwork.MapNetworkDrive "Z:", "\\" & server & "\smbroot$\www-data", 0, usr_name, usr_pass
	
	if Err.Number <> 0 Then
		CreateObject("SAPI.SpVoice").Speak"Не удаось подключить сетевые диски, проверьте сервер."
	else
		CreateObject("SAPI.SpVoice").Speak"Сетевые диски успешно додключены."
	end if
else
		CreateObject("SAPI.SpVoice").Speak"Отключение сетевых дисков"
		WshNetwork.RemoveNetworkDrive "Y:"
		WshNetwork.RemoveNetworkDrive "X:"
		WshNetwork.RemoveNetworkDrive "W:"

		if Err.Number <> 0 Then
			CreateObject("SAPI.SpVoice").Speak"не удалось отключить сетевые диски"
		else
			CreateObject("SAPI.SpVoice").Speak"Завершено"
		end if

	
end if