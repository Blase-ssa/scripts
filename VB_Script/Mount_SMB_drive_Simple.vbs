' ��� ������ ������ �� ������� ������������
On Error Resume Next

' �������� �����, ��������� usr_name
set WshNetwork = WScript.CreateObject("WScript.Network")
usr_name = "user_name"
usr_pass = "put user password here"

'��������� �� ������� ���� (���� ��� ����� ����� ������)
	' ���������� ����
	Err.Clear
	WshNetwork.MapNetworkDrive "v:", "\\ms\Distrib", 0, usr_name, usr_pass
	WshNetwork.MapNetworkDrive "w:", "\\ms\Shared", 0, usr_name, usr_pass
	if Err.Number <> 0 Then
		CreateObject("SAPI.SpVoice").Speak"������� ����� �� ������� ����������"
	else
		CreateObject("SAPI.SpVoice").Speak"������� ����� ������� ����������."
	end if	
