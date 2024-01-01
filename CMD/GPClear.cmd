RD /S /Q "%WinDir%\System32\GroupPolicyUsers"
RD /S /Q "%WinDir%\System32\GroupPolicy"

Reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /f
Reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Group Policy\History" /f
Reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\History" /f

gpupdate /force /boot