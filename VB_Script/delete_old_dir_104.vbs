NumberOfDaysOld = 30		' ��� ����� �������?
sFolder = "E:\SMB\ipcam\104\test"		' ����������
logfile="E:\SMB\ipcam\104\test\delete_log.csv"	' ��� �������
'****************************************************
Set wshShell = WScript.CreateObject ("WSCript.shell")
Set fso = CreateObject("Scripting.FileSystemObject")
Set folder = fso.GetFolder(sFolder)		' �������� ����������
Set subfolders = folder.SubFolders 		' ������ �����

' ����� �������� ������ �����
For each folderIdx In subfolders
	If DateDiff("d", folderIdx.DateLastModified, Now()) - NumberOfDaysOld > 0 Then
		'str = str & folderIdx.Name & vbtab & Now() & vbtab & folderIdx.DateCreated & vbtab & folderIdx.DateLastModified & vbtab & folderIdx.DateLastAccessed & vbtab & DateDiff("d", folderIdx.DateCreated, Now()) & Chr(13) & Chr(10) 
		str = folderIdx.Name & vbtab & Now() & vbtab & folderIdx.DateCreated & vbtab & folderIdx.DateLastModified & vbtab & folderIdx.DateLastAccessed & vbtab & DateDiff("d", folderIdx.DateCreated, Now())
		wshshell.run "cmd /c ""echo " & str & " >> " & logfile & """", 0, True
		folderIdx.Delete
		'str = str & folderIdx.Name & vbtab & DateDiff("d", folderIdx.DateLastModified, Now()) - NumberOfDaysOld & Chr(13) & Chr(10) 
		'str = str & folderIdx.Name & vbtab & DateDiff("d", folderIdx.DateLastModified, Now()) -6 & vbtab & folderIdx.DateLastAccessed & vbtab & folderIdx.DateCreated  & Chr(13) & Chr(10) 
	End If
Next
'wshshell.run "cmd /k ""echo " & str & " >> " & logfile & """", 1, True
'msgbox str

'For Each objSubfolder in colSubfolders    
'    If Date(objSubfolder.DateLastModified) < Date(Now() - NumberOfDaysOld) Then msgbox objSubfolder.Name
'        'objSubfolder.Delete
'    End If
'Next  