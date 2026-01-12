# ZRAM Installer

Автоматический установщик ZRAM дисков с TUI интерфейсом.

## Использование

```bash
sudo ./zram-installer.sh
```

## Что делает скрипт

1. **Анализирует систему** - определяет объем RAM и рассчитывает рекомендуемые размеры
2. **Настраивает ZRAM swap** - создает сжатый swap в памяти
3. **Опционально создает /mnt/zram** - дополнительный ZRAM диск для временных файлов
4. **Генерирует rampak.sh** - скрипт для управления ZRAM
5. **Устанавливает systemd service** - для автозапуска при загрузке

## Формулы расчета

### SWAP размер:
- RAM < 1GB: 20% от RAM
- 1GB ≤ RAM < 4GB: 500MB + 2% от RAM  
- RAM ≥ 4GB: 600MB + 4% от RAM (макс. 1GB)

### /mnt/zram размер:
- RAM < 1GB: 50MB
- 1GB ≤ RAM < 2GB: 100MB
- 2GB ≤ RAM < 4GB: 200MB
- RAM ≥ 4GB: 600MB + 4% от RAM (макс. 1GB)

## Создаваемые файлы

- `/usr/local/bin/rampak.sh` - основной скрипт ZRAM
- `/etc/systemd/system/rampak.service` - systemd unit файл

## Монтируемые папки

При создании /mnt/zram автоматически монтируются:
- `/var/log` → `/mnt/zram/logs`
- `/tmp` → `/mnt/zram/tmp`
- Создается папка `/mnt/zram/shared`