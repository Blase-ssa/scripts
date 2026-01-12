#!/bin/bash

# Функция для получения размера RAM в МБ
get_ram_mb() {
    grep MemTotal /proc/meminfo | awk '{print int($2/1024)}'
}

# Функция расчета размера swap
calculate_swap_size() {
    local ram_mb=$1
    local ram_gb=$((ram_mb / 1024))
    
    if [ $ram_mb -lt 1024 ]; then
        echo $((ram_mb * 20 / 100))
    elif [ $ram_gb -lt 4 ]; then
        echo $((500 + ram_mb * 2 / 100))
    else
        local calc=$((600 + ram_mb * 4 / 100))
        [ $calc -gt 1024 ] && echo 1024 || echo $calc
    fi
}

# Функция расчета размера /mnt/zram
calculate_zram_size() {
    local ram_mb=$1
    local ram_gb=$((ram_mb / 1024))
    
    if [ $ram_mb -lt 1024 ]; then
        echo 50
    elif [ $ram_gb -lt 2 ]; then
        echo 100
    elif [ $ram_gb -lt 4 ]; then
        echo 200
    else
        local calc=$((600 + ram_mb * 4 / 100))
        [ $calc -gt 1024 ] && echo 1024 || echo $calc
    fi
}

# Основная функция
main() {
    # Проверка прав root
    if [ "$EUID" -ne 0 ]; then
        whiptail --title "Ошибка" --msgbox "Скрипт должен быть запущен с правами root (sudo)" 8 50
        exit 1
    fi

    # Получение информации о системе
    RAM_MB=$(get_ram_mb)
    SWAP_SIZE=$(calculate_swap_size $RAM_MB)
    ZRAM_SIZE=$(calculate_zram_size $RAM_MB)

    whiptail --title "ZRAM Installer" --msgbox "Обнаружено RAM: ${RAM_MB}MB\nРекомендуемый swap: ${SWAP_SIZE}MB\nРекомендуемый zram: ${ZRAM_SIZE}MB" 10 50

    # Настройка swap
    SWAP_SIZE=$(whiptail --title "Настройка SWAP" --inputbox "Размер ZRAM swap (MB):" 8 40 "$SWAP_SIZE" 3>&1 1>&2 2>&3)
    [ $? -ne 0 ] && exit 1

    # Выбор создания /mnt/zram
    if whiptail --title "Настройка /mnt/zram" --yesno "Создать ZRAM диск для /mnt/zram?" 8 40; then
        CREATE_ZRAM=true
        ZRAM_SIZE=$(whiptail --title "Размер /mnt/zram" --inputbox "Размер ZRAM диска (MB):" 8 40 "$ZRAM_SIZE" 3>&1 1>&2 2>&3)
        [ $? -ne 0 ] && exit 1
    else
        CREATE_ZRAM=false
    fi

    # Создание скрипта rampak.sh
    cat > /usr/local/bin/rampak.sh << EOF
#!/bin/bash
modprobe zram
sleep 1

# ZRAM для swap
zramctl --find --size=${SWAP_SIZE}M --streams 2 --algorithm zstd
mkswap /dev/zram0
swapon /dev/zram0

EOF

    if [ "$CREATE_ZRAM" = true ]; then
        cat >> /usr/local/bin/rampak.sh << EOF
# ZRAM для /mnt/zram
zramctl --find --size=${ZRAM_SIZE}M --streams 2 --algorithm zstd
mkfs.ext4 /dev/zram1
mkdir -p /mnt/zram
mount /dev/zram1 /mnt/zram
mkdir -p /mnt/zram/shared /mnt/zram/logs /mnt/zram/tmp

# Монтирование папок
mount --bind /var/log /mnt/zram/logs
mount --bind /tmp /mnt/zram/tmp
EOF
    fi

    chmod +x /usr/local/bin/rampak.sh

    # Установка systemd unit
    if whiptail --title "Установка службы" --yesno "Установить systemd unit для автозапуска?" 8 50; then
        cp rampak.service /etc/systemd/system/
        systemctl enable rampak.service
        whiptail --title "Успех" --msgbox "Служба установлена и включена" 8 40
    fi

    whiptail --title "Завершено" --msgbox "Настройка ZRAM завершена!\nСкрипт: /usr/local/bin/rampak.sh" 8 50
}

main "$@"