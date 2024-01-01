Dim oDisplaySubKeys : Set oDisplaySubKeys = CreateObject("Scripting.Dictionary")
Dim oRawEDID : Set oRawEDID = CreateObject("Scripting.Dictionary")
Const HKLM = &H80000002 'HKEY_LOCAL_MACHINE

Int intMonitorCount=0
Int intDisplaySubKeysCount=0
Int i=0
Set oRegistry = GetObject("winmgmts:{impersonationLevel=impersonate}!\\./root/default:StdRegProv")
strDisplayBaseKey = "SYSTEM\CurrentControlSet\Enum\DISPLAY\"
iRC = oRegistry.EnumKey(HKLM, strDisplayBaseKey, strarrDisplaySubKeys)
For Each sKey In strarrDisplaySubKeys
	If sKey ="Default_Monitor" Then
	intDisplaySubKeysCount=intDisplaySubKeysCount - 1
	Else
	oDisplaySubKeys.add sKey, intDisplaySubKeysCount
	End If
	intDisplaySubKeysCount=intDisplaySubKeysCount + 1
Next
strResultDisplaySubKeys=oDisplaySubKeys.Keys
toto=0
For i = 0 to oDisplaySubKeys.Count -1
	strEisaIdBaseKey = strDisplayBaseKey & strResultDisplaySubKeys(i) & "\"
	' Retrieving Pnp-Id from HKLM\SYSTEM\CurrentControlSet\Enum\DISPLAY\EISA-Id and storing in strarrEisaIdSubKeys
	iRC2 = oRegistry.EnumKey(HKLM, strEisaIdBaseKey, strarrEisaIdSubKeys)
	For Each sKey2 In strarrEisaIdSubKeys
		oRegistry.GetMultiStringValue HKLM, strEisaIdBaseKey & sKey2 & "\", "HardwareID", sValue
		For tmpctr=0 to ubound(svalue)
			If lcase(Left(svalue(tmpctr),8))="monitor\" then
				strMsIdBaseKey = strEisaIdBaseKey & sKey2 & "\"
				iRC3 = oRegistry.EnumKey(HKLM, strMsIdBaseKey, strarrMsIdSubKeys)
				For Each sKey3 In strarrMsIdSubKeys
					If skey3="Control" then
						toto=toto + 1
						oRegistry.GetBinaryValue HKLM, strMsIdBaseKey & "Device Parameters\", "EDID", intarrEDID
						strRawEDID=""
						strRawEDIDb=""
						If vartype(intarrEDID) = 8204 then
							For each strByteValue in intarrEDID
								strRawEDID=strRawEDID & Chr(strByteValue)
								strRawEDIDb=strRawEDIDb & Chr(strByteValue)
							Next
						Else
						strRawEDID="EDID Not Available"
						End If
						oRawEDID.add intMonitorCount , strRawEDID
						intMonitorCount=intMonitorCount + 1
					End If
				Next
			End If
		Next
	Next
Next


'*****************************************************************************************
'now the EDID info For each active monitor is stored in an dictionnary of strings called oRawEDID
'so we can process it to get the good stuff out of it which we will store in a 5 dimensional array
'called arrMonitorInfo, the dimensions are as follows:
'0=VESA Mfg ID, 1=VESA Device ID, 2=MFG Date (M/YYYY),3=Serial Num (If available),4=Model Descriptor
'5=EDID Version
'*****************************************************************************************

strResultRawEDID=oRawEDID.Keys

dim arrMonitorInfo()
redim arrMonitorInfo(intMonitorCount-1,5)
dim location(3)

For i=0 to oRawEDID.Count - 1
	If oRawEDID(i) <> "нет доступа к EDID" then
		location(0)=mid(oRawEDID(i),&H36+1,18)
		location(1)=mid(oRawEDID(i),&H48+1,18)
		location(2)=mid(oRawEDID(i),&H5a+1,18)
		location(3)=mid(oRawEDID(i),&H6c+1,18)
		'you can tell If the location contains a serial number If it starts with &H00 00 00 ff
		strSerFind=Chr(&H00) & Chr(&H00) & Chr(&H00) & Chr(&Hff)
		'or a model description If it starts with &H00 00 00 fc
		strMdlFind=Chr(&H00) & Chr(&H00) & Chr(&H00) & Chr(&Hfc)
		
		intSerFoundAt=-1
		intMdlFoundAt=-1
		
		For findit = 0 to 3
			If instr(location(findit),strSerFind)>0 then
				intSerFoundAt=findit
			End If
			If instr(location(findit),strMdlFind)>0 then	
				intMdlFoundAt=findit
			End If
		Next
		'If a location containing a serial number block was found then store it
		If intSerFoundAt<>-1 then tmp=Right(location(intSerFoundAt),14)
		
		If instr(tmp,Chr(&H0a))>0 then
			tmpser=Trim(Left(tmp,instr(tmp,Chr(&H0a))-1))
		Else
			tmpser=Trim(tmp)
		End If
		
		'although it is not part of the edid spec it seems as though the
		'serial number will frequently be preceeded by &H00, this
		'compensates For that
		If Left(tmpser,1)=Chr(0) then 
			tmpser=Right(tmpser,Len(tmpser)-1)
		Else
			tmpser="Сереийный номер отсутствует в EDID"
		End If
		'If a location containing a model number block was found then store it
		If intMdlFoundAt<>-1 then tmp=Right(location(intMdlFoundAt),14)
		
		If instr(tmp,Chr(&H0a))>0 then
			tmpmdl=Trim(Left(tmp,instr(tmp,Chr(&H0a))-1))
		Else
			tmpmdl=Trim(tmp)
		End If
		'although it is not part of the edid spec it seems as though the
		'serial number will frequently be preceeded by &H00, this
		'compensates For that
		If Left(tmpmdl,1)=Chr(0) then 
			tmpmdl=Right(tmpmdl,Len(tmpmdl)-1)
		Else
			tmpmdl="не найдено описание модели"
		End If
		'**************************************************************
		'Next get the mfg date
		'**************************************************************
		'the week of manufacture is stored at EDID offset &H10
		tmpmfgweek=Asc(mid(oRawEDID(i),&H10+1,1))
		'the year of manufacture is stored at EDID offset &H11
		'and is the current year -1990
		tmpmfgyear=(Asc(mid(oRawEDID(i),&H11+1,1)))+1990
		'store it in month/year format
		tmpmdt=month(dateadd("ww",tmpmfgweek,DateValue("1/1/" & tmpmfgyear))) & "/" & tmpmfgyear
		'**************************************************************
		'Next get the edid version
		'**************************************************************
		'the version is at EDID offset &H12
		tmpEDIDMajorVer=Asc(mid(oRawEDID(i),&H12+1,1))
		'the revision level is at EDID offset &H13
		tmpEDIDRev=Asc(mid(oRawEDID(i),&H13+1,1))
		'store it in month/year format
		If tmpEDIDMajorVer < 255-48 and tmpEDIDRev < 255-48 Then
			tmpver=Chr(48+tmpEDIDMajorVer) & "." & Chr(48+tmpEDIDRev)
		Else
			tmpver="не доступно"
		End If
		'**************************************************************
		'Next get the mfg id
		'**************************************************************
		'the mfg id is 2 bytes starting at EDID offset &H08
		'the id is three characters long. using 5 bits to represent
		'each character. the bits are used so that 1=A 2=B etc..
		'
		'get the data
		tmpEDIDMfg=mid(oRawEDID(i),&H08+1,2)
		Char1=0 : Char2=0 : Char3=0
		Byte1=Asc(Left(tmpEDIDMfg,1)) 'get the first half of the string
		Byte2=Asc(Right(tmpEDIDMfg,1)) 'get the first half of the string
		'now shift the bits
		'shift the 64 bit to the 16 bit
		If (Byte1 and 64) > 0 then Char1=Char1+16
		'shift the 32 bit to the 8 bit
		If (Byte1 and 32) > 0 then Char1=Char1+8
		'etc....
		If (Byte1 and 16) > 0 then Char1=Char1+4
		If (Byte1 and 8) > 0 then Char1=Char1+2
		If (Byte1 and 4) > 0 then Char1=Char1+1
		'the 2nd character uses the 2 bit and the 1 bit of the 1st byte
		If (Byte1 and 2) > 0 then Char2=Char2+16
		If (Byte1 and 1) > 0 then Char2=Char2+8
		'and the 128,64 and 32 bits of the 2nd byte
		If (Byte2 and 128) > 0 then Char2=Char2+4
		If (Byte2 and 64) > 0 then Char2=Char2+2
		If (Byte2 and 32) > 0 then Char2=Char2+1
		'the bits For the 3rd character don't need shifting
		'we can use them as they are
		Char3=Char3+(Byte2 and 16)
		Char3=Char3+(Byte2 and 8)
		Char3=Char3+(Byte2 and 4)
		Char3=Char3+(Byte2 and 2)
		Char3=Char3+(Byte2 and 1)
		tmpmfg=Chr(Char1+64) & Chr(Char2+64) & Chr(Char3+64)
		'**************************************************************
		'Next get the device id
		'**************************************************************
		'the device id is 2bytes starting at EDID offset &H0a
		'the bytes are in reverse order.
		'this code is not text. it is just a 2 byte code assigned
		'by the manufacturer. they should be unique to a model
		tmpEDIDDev1=hex(Asc(mid(oRawEDID(i),&H0a+1,1)))
		tmpEDIDDev2=hex(Asc(mid(oRawEDID(i),&H0b+1,1)))
		If Len(tmpEDIDDev1)=1 then tmpEDIDDev1="0" & tmpEDIDDev1
		If Len(tmpEDIDDev2)=1 then tmpEDIDDev2="0" & tmpEDIDDev2
		tmpdev=tmpEDIDDev2 & tmpEDIDDev1
		'**************************************************************
		'finally store all the values into the array
		'**************************************************************
		arrMonitorInfo(i,0)=tmpmfg
		arrMonitorInfo(i,1)=tmpdev
		arrMonitorInfo(i,2)=tmpmdt
		arrMonitorInfo(i,3)=tmpser
		arrMonitorInfo(i,4)=tmpmdl
		arrMonitorInfo(i,5)=tmpver
	End If
	invstr = invstr & "Монитор " & Chr(i+49)	& Chr(13) & Chr(10)
	invstr = invstr & "VESA Manufacturer ID= "	& arrMonitorInfo(i,0)	& Chr(13) & Chr(10)
	invstr = invstr & "Device ID= " 			& arrMonitorInfo(i,1)	& Chr(13) & Chr(10)
	invstr = invstr & "Manufacture Date= "		& arrMonitorInfo(i,2)	& Chr(13) & Chr(10)
	invstr = invstr & "Серийный номер= "		& arrMonitorInfo(i,3)	& Chr(13) & Chr(10)
	invstr = invstr & "Модель= "				& arrMonitorInfo(i,4)	& Chr(13) & Chr(10)
	invstr = invstr & "EDID Version= "			& arrMonitorInfo(i,5)	& Chr(13) & Chr(10)
	
Next
MsgBox invstr