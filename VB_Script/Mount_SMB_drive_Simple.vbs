' при ошибке ничего не говорим пользователю
On Error Resume Next

' получаем логин, формируем usr_name
set WshNetwork = WScript.CreateObject("WScript.Network")
usr_name = "user_name"
usr_pass = "put user password here"

'подключен ли сетевой диск (если нет тогда будет ошибка)
	' подключаем диск
	Err.Clear
	WshNetwork.MapNetworkDrive "v:", "\\ms\Distrib", 0, usr_name, usr_pass
	WshNetwork.MapNetworkDrive "w:", "\\ms\Shared", 0, usr_name, usr_pass
	if Err.Number <> 0 Then
		CreateObject("SAPI.SpVoice").Speak"Сетевые диски Не удалось подключить"
	else
		CreateObject("SAPI.SpVoice").Speak"Сетевые диски успешно подключены."
	end if	
