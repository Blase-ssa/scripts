#!/usr/bin/env bash

[[ -f 'env.sh' ]] && source env.sh

echo "=== Демонстрация правильного QR-кода для AmneziaWG ==="
echo

# Пример правильной конфигурации для мобильного клиента AmneziaWG
cat <<'EOF'
Правильный формат конфигурации для мобильного клиента AmneziaWG:

[Interface]
PrivateKey = 4Mw7h5O1qNgnDC8Aq7MfZlc7Ruw4QRJSOlwNB4Tdo0w=
Address = 10.8.0.2/24
DNS = 1.1.1.1
MTU = 1280
Jc = 4
Jmin = 50
Jmax = 1000
S1 = 200
S2 = 200
H1 = 1234567890
H2 = 987654321

[Peer]
PublicKey = ENW723x5b0m9JKoyKsebqbBUuW7UyxGSheHkbb1GF38=
PresharedKey = fL/V9X90dBDtmGmYs4yeDJtqCGRGlq8auCeWHKFhcL0=
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
Endpoint = blase-vps2.gotdns.ch:51820

Параметры AmneziaWG:
- MTU: максимальный размер пакета
- Jc: количество мусорных пакетов (3-10)
- Jmin: минимальный размер мусорного пакета (15-100)
- Jmax: максимальный размер мусорного пакета (201-1000)
- S1: размер мусора в инициализирующем пакете (15-100)
- S2: размер мусора в ответном пакете (15-100)
- H1: магический заголовок инициализирующего пакета
- H2: магический заголовок ответного пакета

Проверка соответствия ключей:
EOF

echo
echo "Проверяем соответствие ключей из wg_config.json:"

# Проверяем ключи из конфигурации
PRIVATE_KEY="4Mw7h5O1qNgnDC8Aq7MfZlc7Ruw4QRJSOlwNB4Tdo0w="
EXPECTED_PUBLIC="qJChvHnfJWWMLhJYQdQUjKU0HWLCW4yX1iDtupszSEg="

GENERATED_PUBLIC=$(echo "$PRIVATE_KEY" | $WGCMD pubkey)

echo "Приватный ключ клиента: $PRIVATE_KEY"
echo "Ожидаемый публичный ключ: $EXPECTED_PUBLIC"
echo "Сгенерированный публичный: $GENERATED_PUBLIC"

if [[ "$EXPECTED_PUBLIC" == "$GENERATED_PUBLIC" ]]; then
    echo "✓ Ключи клиента соответствуют"
else
    echo "✗ ОШИБКА: Ключи клиента НЕ соответствуют!"
fi

echo
echo "Проверяем ключи сервера:"
SRV_PRIVATE="0F4g9O7ML09apdZPykLvO/KADGgA53sSgproCDZt92Q="
SRV_EXPECTED="ENW723x5b0m9JKoyKsebqbBUuW7UyxGSheHkbb1GF38="

SRV_GENERATED=$(echo "$SRV_PRIVATE" | $WGCMD pubkey)

echo "Приватный ключ сервера: $SRV_PRIVATE"
echo "Ожидаемый публичный ключ: $SRV_EXPECTED"
echo "Сгенерированный публичный: $SRV_GENERATED"

if [[ "$SRV_EXPECTED" == "$SRV_GENERATED" ]]; then
    echo "✓ Ключи сервера соответствуют"
else
    echo "✗ ОШИБКА: Ключи сервера НЕ соответствуют!"
fi