#!/bin/sh

CA_DIR="$(pwd)/../cacertshome/intermediate"

#openssl req -new -nodes -out ocspSigning.csr -keyout ocspSigning.key


cat > ocspserver.ext << EOF
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = OCSPSigning
certificatePolicies=@entrust,2.23.140.1.1
noCheck = yes


[entrust]
policyIdentifier=2.16.840.1.114028.10.1.2
CPS.1=http://$(hostname -f):8080/rpa

EOF

openssl ca -batch -passin file:$CA_DIR/mypass.enc -keyfile $CA_DIR/private/intermediate.cakey.pem -cert $CA_DIR/certs/intermediate.cacert.pem -in ocspSigning.csr -notext -out ocspSigning.crt -extfile ocspserver.ext -config $CA_DIR/ca.cnf



openssl ocsp -index $CA_DIR/index.txt -port 8080 -rsigner ocspSigning.crt -rkey ocspSigning.key -CA $CA_DIR/certs/intermediate.cacert.pem -text -out log.txt -ignore_err &


