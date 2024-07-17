#!/bin/bash

# Caminho para o executável do ZAP
ZAP_PATH="/home/zero/Downloads/ZAP_2.14.0"

# URL alvo
TARGET_URL="http://localhost:80"

# Caminho para salvar o relatório JSON
REPORT_PATH="/home/zero/"

# Inicia o ZAP em modo daemon na porta 8080
nohup $ZAP_PATH/zap.sh -daemon -port 8080 -config api.disablekey=true &

# Aguarda o ZAP iniciar completamente
sleep 10

# Inicia spider scan para posteriormente iniciar active scan
curl -G "http://localhost:8080/JSON/spider/action/scan/" \
--data-urlencode "url=$TARGET_URL" \
--data-urlencode "maxchildren=10"  \
--data-urlencode "recurse=true"

sleep 5

# Espera scan concluir...
SPIDERSCANID=0

while [ "$SPIDERSCANID" -ne "100" ]
do
curl -G "http://localhost:8080/JSON/spider/view/status/" --data-urlencode "scanId=0" > TEMPSCANID.txt
SPIDERSCANID=$(cat TEMPSCANID.txt | sed 's/"//g' | grep -oE '{status:([^,]+)'|sed 's/}//' | sed 's/status://')
echo "o status do spider scan: $SPIDERSCANID%"
done


# Inica scan ativo
curl -G "http://localhost:8080/JSON/ascan/action/scan/" \
--data-urlencode "url=$TARGET_URL" \
--data-urlencode "recurse=true" \
--data-urlencode "inScopeOnly=false" \
--data-urlencode "scanPolicyName=Default Policy" \
--data-urlencode "method=GET" \
--data-urlencode "postdata=""" \
--data-urlencode "contextId="

# Espera scan concluir...
ACTIVESCANID=0

while [ "$ACTIVESCANID" -ne "100" ]
do
curl -G "http://localhost:8080/JSON/ascan/view/status/" --data-urlencode "scanId=0" > TEMPSCANID2.txt
ACTIVESCANID=$(cat TEMPSCANID2.txt | sed 's/"//g' | grep -oE '{status:([^,]+)'|sed 's/}//' | sed 's/status://')
echo "o status do active scan: $ACTIVESCANID%"
done

# Gerar Report
TITLEREPORT="TEST5"
curl -G "http://localhost:8080/JSON/reports/action/generate/" \
--data-urlencode "title=$TITLEREPORT" \
--data-urlencode "template=traditional-json" \
--data-urlencode "sites=$TARGET_URL"

