' ��� ������ ������ �� ������� ������������
On Error Resume Next

' �������� �����, ��������� usr_name
set WshNetwork = WScript.CreateObject("WScript.Network")
usr_name = "User"
usr_pass = "Password"
server = "ServerName or IP"

'��������� �� ������� ���� (���� ��� ����� ����� ������)
Err.Clear
WshNetwork.RemoveNetworkDrive "Z:"
if Err.Number <> 0 Then
	' ���������� ����
	WshNetwork.MapNetworkDrive "Y:", "\\" & server & "\smbroot$\Music", 0, usr_name, usr_pass
	WshNetwork.MapNetworkDrive "X:", "\\" & server & "\smbroot$\photo", 0, usr_name, usr_pass
	WshNetwork.MapNetworkDrive "W:", "\\" & server & "\smbroot$\rest", 0, usr_name, usr_pass
	WshNetwork.MapNetworkDrive "Z:", "\\" & server & "\smbroot$\www-data", 0, usr_name, usr_pass
	
	if Err.Number <> 0 Then
		CreateObject("SAPI.SpVoice").Speak"�� ������ ���������� ������� �����, ��������� ������."
	else
		CreateObject("SAPI.SpVoice").Speak"������� ����� ������� ����������."
	end if
else
		CreateObject("SAPI.SpVoice").Speak"���������� ������� ������"
		WshNetwork.RemoveNetworkDrive "Y:"
		WshNetwork.RemoveNetworkDrive "X:"
		WshNetwork.RemoveNetworkDrive "W:"

		if Err.Number <> 0 Then
			CreateObject("SAPI.SpVoice").Speak"�� ������� ��������� ������� �����"
		else
			CreateObject("SAPI.SpVoice").Speak"���������"
		end if

	
end if