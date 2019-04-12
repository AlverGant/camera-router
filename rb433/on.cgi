#!/bin/ash

urldecode() {
    # urldecode <string>

    local url_encoded="${1//+/ }"
    printf '%b' "${url_encoded//%/\\x}"
}

IFS='=&'
set -- $QUERY_STRING


 echo "content-type: text/plain"
  echo
  echo -e ""


uci set wireless.@wifi-iface[0].ssid=`urldecode $2`
uci set wireless.@wifi-iface[0].key=`urldecode $4`
uci commit wireless
wifi

ping -c 1 10.0.0.1 &> /dev/null && echo Camera Conectada com Sucesso || echo Erro, favor refazer o processo.



