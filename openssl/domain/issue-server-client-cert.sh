#!/bin/sh

if [ "$#" -ne 2 ]
then
  echo "Usage: Must supply a domain and IP"
  exit 1
fi

DOMAIN=$1
DOMAIN_IP=$2

CA_DIR="$(pwd)/../cacertshome/intermediate"

#openssl genrsa -out $DOMAIN.key 2048
#openssl req -new -key $DOMAIN.key -out $DOMAIN.csr

cat > $DOMAIN.ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth,clientAuth
authorityInfoAccess=OCSP;URI:http://$(hostname -f):8080/
subjectAltName = @alt_names
certificatePolicies=@entrust,2.23.140.1.1


[entrust]
policyIdentifier=2.16.840.1.114028.10.1.2
CPS.1=http://$(hostname -f):8080/rpa

[alt_names]
DNS.1 = $DOMAIN
IP.1 = $DOMAIN_IP
EOF


#openssl x509 -req -in $DOMAIN.csr -passin file:$CA_DIR/mypass.enc -CA $CA_DIR/certs/intermediate.cacert.pem -CAkey $CA_DIR/private/intermediate.cakey.pem -CAcreateserial -out $DOMAIN.crt -days 825 -sha256 -extfile $DOMAIN.ext

#openssl ca -passin file:$CA_DIR/mypass.enc -keyfile $CA_DIR/private/intermediate.cakey.pem -cert $CA_DIR/certs/intermediate.cacert.pem -in $DOMAIN.csr -out $DOMAIN.crt -config $CA_DIR/ca.conf -days 825 -sha256 -extfile $DOMAIN.ext
openssl ca -batch -passin file:$CA_DIR/mypass.enc  -keyfile $CA_DIR/private/intermediate.cakey.pem -cert $CA_DIR/certs/intermediate.cacert.pem -policy policy_anything -notext -out $DOMAIN.crt -config $CA_DIR/ca.cnf -days 825 -extfile $DOMAIN.ext -in $DOMAIN.csr

cp $CA_DIR/../certs/cacert.pem $DOMAIN-root.pem
cp $CA_DIR/certs/intermediate.cacert.pem $DOMAIN-intermediate.pem



openssl genrsa -out $DOMAIN-client.key 2048 -subj "/C=IN/ST=Karnataka/L=Banagalore /O=DE/OU=DE/CN=DE/emailAddress=akash@abc.com"
openssl req -new -key $DOMAIN-client.key -out $DOMAIN-client.csr

rm -rf $DOMAIN.ext

cat > $DOMAIN.ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth
authorityInfoAccess=OCSP;URI:http://$(hostname -f):8080/
subjectAltName = @alt_names
certificatePolicies=@entrust,2.23.140.1.1


[entrust]
policyIdentifier=2.16.840.1.114028.10.1.2
CPS.1=http://$(hostname -f):8080/rpa

[alt_names]
DNS.1 = $DOMAIN
IP.1 = $DOMAIN_IP
EOF


openssl ca -batch -passin file:$CA_DIR/mypass.enc  -keyfile $CA_DIR/private/intermediate.cakey.pem -cert $CA_DIR/certs/intermediate.cacert.pem -policy policy_anything -notext -out $DOMAIN-client.crt -config $CA_DIR/ca.cnf -days 825 -extfile $DOMAIN.ext -in $DOMAIN-client.csr

cat $DOMAIN-root.pem $DOMAIN-intermediate.pem $DOMAIN-client.crt >$DOMAIN-client-chain.crt


openssl pkcs12  -export -out  $DOMAIN-client.pfx -inkey $DOMAIN-client.key -in $DOMAIN-client-chain.crt  -certfile $DOMAIN-root.pem


