#!/bin/sh

CA_DIR="$(pwd)/../cacertshome/intermediate"
DEFAULT_SERIEL_NO=100

echo "Seriel Detials" && cat $CA_DIR/index.txt | awk '{print $3,$5}'

read -p "Enter Seriel Number [$DEFAULT_SERIEL_NO]: " SERIEL_NO
SERIEL_NO=${SERIEL_NO:-${DEFAULT_SERIEL_NO}}

openssl ca -revoke $CA_DIR/certs/$SERIEL_NO.pem -config $CA_DIR/ca.cnf -passin file:$CA_DIR/mypass.enc


