# ssh-menu
## Description
This script will parse "$HOME\.ssh\config" file in search of ssh configuration and printout a menu list with the host list. Giving you the menu for SSH connection to printed hosts.

---

## installation
⚠️ Sorry, I was too lazy to translate itto English ⚠️
Есть несколько удобных способов превратить твой PowerShell‑скрипт в «глобальную» команду, которую можно вызвать из любого каталога. Ниже — самый чистый и практичный подход.

---

1. Создай папку, если её нет:

```powershell
New-Item -ItemType Directory -Force "$HOME\Documents\PowerShell\Scripts"
```

2. Копировать скрипт sshmenu.ps1 туда, например:

```
cp sshmenu.ps1 $HOME\Documents\PowerShell\Scripts\
```

3. Добавь её в PATH 

4. Теперь можешь запускать его так:

```
sshmenu
```

или

```
sshmenu.ps1
```

Если не запускается — см. политику выполнения:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---
