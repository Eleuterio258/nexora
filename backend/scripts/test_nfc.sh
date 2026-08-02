#!/usr/bin/env bash
#
# Script de teste rápido para registo de assiduidade por NFC.
# Uso:
#   export BASE_URL="https://api.nexora.e258tech.tech"
#   export EMAIL="eleuterio.notico@e258tech.tech"
#   export PASSWORD="1234567890"
#   ./scripts/test_nfc.sh
#

set -euo pipefail

BASE_URL="${BASE_URL:-https://api.nexora.e258tech.tech}"
EMAIL="${EMAIL:-}"
PASSWORD="${PASSWORD:-}"
NFC_TAG_ID="${NFC_TAG_ID:-0E6A8A2584695F}"

if [[ -z "$EMAIL" || -z "$PASSWORD" ]]; then
  echo "Erro: define as variáveis EMAIL e PASSWORD."
  echo "Exemplo:"
  echo '  export EMAIL="utilizador@exemplo.com"'
  echo '  export PASSWORD="123456"'
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1 && ! command -v python >/dev/null 2>&1; then
  echo "Erro: python3 ou python é necessário para processar o JSON."
  exit 1
fi

PYTHON="$(command -v python3 || command -v python)"

echo "========================================"
echo "URL base: $BASE_URL"
echo "Email:    $EMAIL"
echo "========================================"
echo ""

# 1. Login
echo "[1/3] A fazer login..."
LOGIN_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")

HTTP_CODE=$(echo "$LOGIN_RESPONSE" | tail -n1)
BODY=$(echo "$LOGIN_RESPONSE" | sed '$d')

if [[ "$HTTP_CODE" != "200" && "$HTTP_CODE" != "201" ]]; then
  echo "Erro no login (HTTP $HTTP_CODE):"
  echo "$BODY" | "$PYTHON" -m json.tool 2>/dev/null || echo "$BODY"
  exit 1
fi

TOKEN=$(echo "$BODY" | "$PYTHON" -c "import sys, json; print(json.load(sys.stdin).get('token') or json.load(sys.stdin).get('access_token') or json.load(sys.stdin).get('accessToken', ''))" 2>/dev/null || true)

if [[ -z "$TOKEN" ]]; then
  echo "Não foi possível extrair o token da resposta:"
  echo "$BODY" | "$PYTHON" -m json.tool 2>/dev/null || echo "$BODY"
  exit 1
fi

echo "Login OK."
echo ""

# 2. Verificar métodos activos
echo "[2/3] A verificar métodos activos..."
METODOS_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/api/self-service/assiduidade/metodos" \
  -H "Authorization: Bearer $TOKEN")

HTTP_CODE=$(echo "$METODOS_RESPONSE" | tail -n1)
BODY=$(echo "$METODOS_RESPONSE" | sed '$d')

if [[ "$HTTP_CODE" != "200" ]]; then
  echo "Erro ao obter métodos (HTTP $HTTP_CODE):"
  echo "$BODY" | "$PYTHON" -m json.tool 2>/dev/null || echo "$BODY"
  exit 1
fi

NFC_ATIVO=$(echo "$BODY" | "$PYTHON" -c "import sys, json; d=json.load(sys.stdin); print(d.get('metodos',{}).get('nfc',{}).get('ativo',False))" 2>/dev/null || echo "False")
echo "NFC ativo: $NFC_ATIVO"
echo ""

# 3. Testar registo por NFC
echo "[3/3] A testar registo por NFC..."
NFC_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/api/self-service/assiduidade/ponto" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"metodo\":\"nfc\",\"dados\":{\"nfc_tag_id\":\"$NFC_TAG_ID\"}}")

HTTP_CODE=$(echo "$NFC_RESPONSE" | tail -n1)
BODY=$(echo "$NFC_RESPONSE" | sed '$d')

echo "HTTP $HTTP_CODE"
echo "$BODY" | "$PYTHON" -m json.tool 2>/dev/null || echo "$BODY"
echo ""

if [[ "$HTTP_CODE" == "201" ]]; then
  echo "✅ Registo por NFC bem-sucedido."
else
  echo "❌ Registo por NFC falhou."
  exit 1
fi
