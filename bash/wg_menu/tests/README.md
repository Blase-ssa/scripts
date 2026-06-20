# Тесты для AWG (Amnezia WireGuard)

Этот каталог содержит автоматизированные тесты для bash-скриптов AWG, написанные с использованием [Bats](https://github.com/bats-core/bats-core).

## Структура тестов

- `test_env.bats` - тесты переменных окружения
- `test_awg_functions.bats` - тесты основных функций из awg-function.lib.sh
- `test_config_generation.bats` - тесты генерации серверных конфигураций
- `test_client_config.bats` - тесты генерации клиентских конфигураций
- `test_public_ip.bats` - тесты получения публичного IP
- `run_tests.sh` - скрипт для запуска всех тестов

## Установка Bats

### Ubuntu/Debian
```bash
sudo apt-get install bats
```

### CentOS/RHEL
```bash
git clone https://github.com/bats-core/bats-core.git
cd bats-core
sudo ./install.sh /usr/local
```

## Запуск тестов

### Запуск всех тестов
```bash
./run_tests.sh
```

### Запуск отдельного файла тестов
```bash
bats test_awg_functions.bats
```

### Запуск конкретного теста
```bash
bats -f "get_servers_list" test_awg_functions.bats
```

## Что тестируется

### Основные функции (test_awg_functions.bats)
- `get_servers_list()` - получение списка серверов
- `get_server_ip()` - получение IP сервера
- `get_clients_ip_list()` - получение списка IP клиентов
- `get_users_list()` - получение списка пользователей
- `offer_client_ip()` - предложение следующего доступного IP
- `get_user_uid()` - получение UUID пользователя
- `delete_server()` - удаление сервера
- `delete_user()` - удаление пользователя

### Генерация конфигураций (test_config_generation.bats)
- Создание серверных конфигурационных файлов
- Проверка наличия необходимых секций
- Проверка параметров Amnezia

### Клиентские конфигурации (test_client_config.bats)
- Генерация клиентских конфигураций
- Проверка корректности данных пользователя и сервера

### Переменные окружения (test_env.bats)
- Проверка наличия и корректности переменных из env.sh

### Публичный IP (test_public_ip.bats)
- Тестирование функции получения публичного IP
- Обработка ошибок сети