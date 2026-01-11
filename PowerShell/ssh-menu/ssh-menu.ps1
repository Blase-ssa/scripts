$path = Join-Path $HOME ".ssh\config"

if (-not (Test-Path $path)) {
    Write-Host "Файл $path не найден"
    exit
}

# Читаем только Host
$hosts = @(Select-String -Path $path -Pattern '^\s*Host\s+(.+)$' | ForEach-Object {
    $_.Matches[0].Groups[1].Value
})

if ($hosts.Count -eq 0) {
    Write-Host "В файле нет Host"
    exit
}

# Добавляем пункт Выход
$hosts += '<< Exit >>'

# Меню со стрелками
$index = 0
$selected = $null
$done = $false

while ($true) {
    Clear-Host
    Write-Host "Выберите хост (Esc - Выход):`n"

    for ($i = 0; $i -lt $hosts.Count; $i++) {
        if ($i -eq $index) {
            Write-Host "> $($hosts[$i])"  # выделенный пункт
        } else {
            Write-Host "  $($hosts[$i])"
        }
    }

    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

    switch ($key.VirtualKeyCode) {
        38 { $index = [Math]::Max(0, $index - 1) }                 # Up
        40 { $index = [Math]::Min($hosts.Count - 1, $index + 1) }  # Down
        27 { exit }                                                # Esc
        13 {
            $selected = $hosts[$index]
            if ($selected -eq '<< Exit >>') { exit }
            $done = $true
        }                                                           # Enter
    }

    if ($selected) {
        Write-Host "Подключаюсь: $selected"
        & 'ssh' $selected
        $selected = $null
    } 
}
