#!/usr/bin/env bash

# Скрипт для запуска всех тестов
echo "Запуск тестов AWG..."

# Проверяем наличие bats
if ! command -v bats &> /dev/null; then
    echo "ОШИБКА: bats не установлен"
    echo "Установите bats: https://github.com/bats-core/bats-core"
    exit 1
fi

# Запускаем все тесты
echo "=== Тестирование переменных окружения ==="
bats test_env.bats

echo -e "\n=== Тестирование основных функций ==="
bats test_awg_functions.bats

echo -e "\n=== Тестирование генерации конфигураций ==="
bats test_config_generation.bats

echo -e "\n=== Тестирование клиентских конфигураций ==="
bats test_client_config.bats

echo -e "\n=== Тестирование получения публичного IP ==="
bats test_public_ip.bats

echo -e "\n=== Тестирование получения публичного IP ==="
bats test_get_input.bats

echo -e "\n=== Все тесты завершены ==="