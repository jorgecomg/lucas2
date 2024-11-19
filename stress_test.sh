#!/bin/bash

URL_BASE="http://localhost:5001"
URL_LOGIN="${URL_BASE}/auth/login"
URL_CADASTRO="${URL_BASE}/auth/cadastro"
NUM_REQUESTS=500
CONCURRENT=20
DELAY=0.05

SUCCESS_FILE="/tmp/stress_success"
ERROR_FILE="/tmp/stress_errors"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

increment_success() {
    local current
    current=$(cat $SUCCESS_FILE 2>/dev/null || echo 0)
    echo $((current + 1)) > $SUCCESS_FILE
}

increment_error() {
    local current
    current=$(cat $ERROR_FILE 2>/dev/null || echo 0)
    echo $((current + 1)) > $ERROR_FILE
}

do_login() {
    local id=$1
    local response=$(curl -s -w "\n%{http_code}" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        --cookie-jar /tmp/cookies_$id.txt \
        -d "{\"email\":\"user${id}@test.com\",\"password\":\"pass${id}\"}" \
        "$URL_LOGIN")
    
    local http_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ] || [ "$http_code" = "302" ]; then
        echo -e "${GREEN}Login $id: Sucesso (HTTP $http_code)${NC}"
        increment_success
    else
        echo -e "${RED}Login $id: Falha (HTTP $http_code)${NC}"
        echo -e "${YELLOW}Resposta: $body${NC}"
        increment_error
    fi
    
    rm -f /tmp/cookies_$id.txt
}

do_register() {
    local id=$1
    local response=$(curl -s -w "\n%{http_code}" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        --cookie-jar /tmp/cookies_$id.txt \
        -d "{\"nome\":\"User ${id}\",\"email\":\"user${id}@test.com\",\"password\":\"pass${id}\"}" \
        "$URL_CADASTRO")
    
    local http_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ] || [ "$http_code" = "302" ]; then
        echo -e "${GREEN}Cadastro $id: Sucesso (HTTP $http_code)${NC}"
        increment_success
    else
        echo -e "${RED}Cadastro $id: Falha (HTTP $http_code)${NC}"
        echo -e "${YELLOW}Resposta: $body${NC}"
        increment_error
    fi
    
    rm -f /tmp/cookies_$id.txt
}

show_progress() {
    local current_success
    local current_errors
    current_success=$(cat $SUCCESS_FILE 2>/dev/null || echo 0)
    current_errors=$(cat $ERROR_FILE 2>/dev/null || echo 0)
    local current_total=$1
    
    echo "----------------------------------------"
    echo "Progresso: $current_total de $NUM_REQUESTS requisições"
    echo "Sucesso: $current_success"
    echo "Erros: $current_errors"
    if [ $current_total -gt 0 ]; then
        echo "Taxa de sucesso atual: $(( (current_success * 100) / current_total ))%"
    else
        echo "Taxa de sucesso atual: 0%"
    fi
    echo "----------------------------------------"
}

echo "0" > $SUCCESS_FILE
echo "0" > $ERROR_FILE

echo "Testando conexão com a API"
if curl -s "$URL_BASE" > /dev/null; then
    echo "API Up"
else
    echo "API Down"
fi

echo "Iniciando teste de estresse"
echo "URL Base: $URL_BASE"
echo "URL Login: $URL_LOGIN"
echo "URL Cadastro: $URL_CADASTRO"
echo "Total de requisições: $NUM_REQUESTS"
echo "Requisições simultâneas: $CONCURRENT"
echo "Delay entre requisições: ${DELAY}s"

pids=()

count=0

for ((i=1; i<=$NUM_REQUESTS; i++)); do
    if [ $((i % 2)) -eq 0 ]; then
        do_login $i &
    else
        do_register $i &
    fi
    
    pids+=($!)
    ((count++))
    
    if [ ${#pids[@]} -eq $CONCURRENT ]; then
        for pid in ${pids[@]}; do
            wait $pid
        done
        pids=()
        show_progress $count
        sleep $DELAY
    fi
done

for pid in ${pids[@]}; do
    wait $pid
done

final_success=$(cat $SUCCESS_FILE)
final_errors=$(cat $ERROR_FILE)

echo "============================================"
echo "Teste finalizado"
echo "Total de requisições: $NUM_REQUESTS"
echo "Sucesso: $final_success"
echo "Erros: $final_errors"
echo "Taxa de sucesso final: $(( (final_success * 100) / NUM_REQUESTS ))%"
echo "============================================"

rm -f $SUCCESS_FILE
rm -f $ERROR_FILE
rm -f /tmp/cookies_*.txt