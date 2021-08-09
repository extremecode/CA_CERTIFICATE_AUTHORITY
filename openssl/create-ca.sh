#!/bin/sh

CA_ROOT_DIR="$(pwd)/cacertshome"
OCSP_SERVER_PORT=8080
rm -rf $CA_ROOT_DIR

echo "`date +\"%F %T\"` [INFO] Creating CACERTS root dir CA_ROOT_DIR "
mkdir -p $CA_ROOT_DIR

echo "`date +\"%F %T\"` [INFO] Creating CACERTS certs dir CA_ROOT_DIR/certs "
mkdir -p $CA_ROOT_DIR/certs


echo "`date +\"%F %T\"` [INFO] Creating CACERTS private key dir CA_ROOT_DIR/private "
mkdir -p $CA_ROOT_DIR/private

echo "`date +\"%F %T\"` [INFO] Creating CACERTS seriel file to keep  track of the last serial number that was used to issue a certificate"
echo 01 > $CA_ROOT_DIR/serial

echo "`date +\"%F %T\"` [INFO] Creating CACERTS database index.txt"
touch $CA_ROOT_DIR/index.txt

#echo "`date +\"%F %T\"` [INFO] Copying /etc/pki/tls/openssl.cnf to $CA_ROOT_DIR directory"
#cp /etc/pki/tls/openssl.cnf $CA_ROOT_DIR/

echo "`date +\"%F %T\"` [INFO] Creating ca.conf in  $CA_ROOT_DIR directory"

echo '

[ ca ]
default_ca      = CA_default            # The default ca section

[ CA_default ]
dir             = '$CA_ROOT_DIR'             # Where everything is kept
certs           = $dir/certs            # Where the issued certs are kept
database        = $dir/index.txt        # database index file.
                                        # several certs with same subject.
new_certs_dir   = $dir/certs            # default place for new certs.
certificate     = $dir/certs/cacert.pem       # The CA certificate
serial          = $dir/serial           # The current serial number
crlnumber       = $dir/crlnumber        # the current crl number
                                        # must be commented out to leave a V1 CRL
private_key     = $dir/private/cakey.pem # The private key

name_opt        = ca_default            # Subject Name options
cert_opt        = ca_default            # Certificate field options

default_days    = 365                   # how long to certify for
default_crl_days= 30                    # how long before next CRL
default_md      = sha256                # use SHA-256 by default
preserve        = no                    # keep passed DN ordering
policy          = policy_match

[ policy_match ]
countryName             = match
stateOrProvinceName     = match
organizationName        = match
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ policy_anything ]
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ req ]
default_bits            = 4096
default_md              = sha256
default_keyfile         = privkey.pem
distinguished_name      = req_distinguished_name
x509_extensions         = v3_ca
string_mask             = nombstr

[ req_distinguished_name ]
countryName                     = Country Name (2 letter code)
countryName_default             = IN
countryName_min                 = 2
countryName_max                 = 2
stateOrProvinceName             = State or Province Name (full name)
stateOrProvinceName_default     = Karnataka
localityName                    = Locality Name (eg, city)
localityName_default            = BANGALORE
0.organizationName              = Organization Name (eg, company)
0.organizationName_default      = Micro Focus
organizationalUnitName          = Organizational Unit Name (eg, section)
organizationalUnitName_default  = ITOM
commonName                      = Common Name (eg, your name or your servers hostname)
commonName_default              = nmccloudvm35.ftc.hpeswlab.net
commonName_max                  = 64
emailAddress                    = Email Address
emailAddress_default            = akash.gupta2@microfocus.com
emailAddress_max                = 64

[ v3_ca ]
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid:always,issuer
basicConstraints = critical,CA:true

[ v3_intermediate_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, nonRepudiation,digitalSignature, cRLSign, keyCertSign
extendedKeyUsage = OCSPSigning,serverAuth,clientAuth,timeStamping,codeSigning,emailProtection

[ usr_cert ]
authorityInfoAccess = OCSP;URI:http://'$(hostname -f)':'$OCSP_SERVER_PORT'

[ v3_OCSP ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = OCSPSigning

trustList=2.16.840.1.113730.1.900
# these four are already defined in my OpenSSL, but they're here for if you're using an older version:
businessCategory=2.5.4.15
jurisdictionOfIncorporationLocalityName=1.3.6.1.4.1.311.60.2.1.1
jurisdictionOfIncorporationStateOrProvinceName=1.3.6.1.4.1.311.60.2.1.2
jurisdictionOfIncorporationCountryName=1.3.6.1.4.1.311.60.2.1.3

' > $CA_ROOT_DIR/ca.cnf

echo "`date +\"%F %T\"` [INFO] Switching to root CA directory $CA_ROOT_DIR"
cd $CA_ROOT_DIR

echo "`date +\"%F %T\"` [INFO] Creating root CA private key"
echo "CARoot@123" > mypass.enc
openssl  genrsa -des3 -passout file:$CA_ROOT_DIR/mypass.enc -out $CA_ROOT_DIR/private/cakey.pem 4096

echo "`date +\"%F %T\"` [INFO] Cerifying root CA key in CAKEYREPS.txt"
openssl rsa -noout -text -in $CA_ROOT_DIR/private/cakey.pem -passin file:mypass.enc | head -2

echo "`date +\"%F %T\"` [INFO] Creating root CA certificate"
openssl req -new -x509 -days 3650 -passin file:$CA_ROOT_DIR/mypass.enc -config $CA_ROOT_DIR/ca.cnf -extensions v3_ca -key $CA_ROOT_DIR/private/cakey.pem -out $CA_ROOT_DIR/certs/cacert.pem

echo "`date +\"%F %T\"` [INFO] Creating root CA certificate to PEM format"
openssl x509 -in $CA_ROOT_DIR/certs/cacert.pem -out $CA_ROOT_DIR/certs/cacert.pem -outform PEM

echo "`date +\"%F %T\"` [INFO] Checking generated certificate"
openssl x509 -noout -text -in $CA_ROOT_DIR/certs/cacert.pem | head -20

echo "`date +\"%F %T\"` [INFO] Creating Intermediate CA directories"
mkdir -p $CA_ROOT_DIR/intermediate
mkdir -p $CA_ROOT_DIR/intermediate/certs
mkdir -p $CA_ROOT_DIR/intermediate/csr
mkdir -p $CA_ROOT_DIR/intermediate/private

echo "`date +\"%F %T\"` [INFO] Creating Intermediate CA database/serial/crl configuraiton"
touch $CA_ROOT_DIR/intermediate/index.txt
echo 01 > $CA_ROOT_DIR/intermediate/serial
echo 01 > $CA_ROOT_DIR/intermediate/crlnumber

echo '

[ ca ]
default_ca      = CA_default            # The default ca section

[ CA_default ]
dir             = '$CA_ROOT_DIR'/intermediate               # Where everything is kept
certs           = $dir/certs            # Where the issued certs are kept
database        = $dir/index.txt        # database index file.
                                        # several certs with same subject.
new_certs_dir   = $dir/certs            # default place for new certs.
certificate     = $dir/certs/intermediate.cacert.pem   # The CA certificate
serial          = $dir/serial           # The current serial number
crlnumber       = $dir/crlnumber        # the current crl number
                                        # must be commented out to leave a V1 CRL
private_key     = $dir/private/intermediate.cakey.pem  # The private key

name_opt        = ca_default            # Subject Name options
cert_opt        = ca_default            # Certificate field options

default_days    = 365                   # how long to certify for
default_crl_days= 30                    # how long before next CRL
default_md      = sha256                # use SHA-256 by default
preserve        = no                    # keep passed DN ordering
policy          = policy_anything

[ policy_match ]
countryName             = match
stateOrProvinceName     = match
organizationName        = match
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ policy_anything ]
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ req ]
default_bits            = 4096
default_md              = sha256
default_keyfile         = privkey.pem
distinguished_name      = req_distinguished_name
x509_extensions         = v3_ca
string_mask             = nombstr

[ req_distinguished_name ]
countryName                     = Country Name (2 letter code)
countryName_default             = IN
countryName_min                 = 2
countryName_max                 = 2
stateOrProvinceName             = State or Province Name (full name)
stateOrProvinceName_default     = Karnataka
localityName                    = Locality Name (eg, city)
localityName_default            = BANGALORE
0.organizationName              = Organization Name (eg, company)
0.organizationName_default      = Micro Focus
organizationalUnitName          = Organizational Unit Name (eg, section)
organizationalUnitName_default  = ITOM
commonName                      = Common Name (eg, your name or your servers hostname)
commonName_default              = nmccloudvm35.ftc.hpeswlab.net
commonName_max                  = 64
emailAddress                    = Email Address
emailAddress_default            = akash.gupta2@microfocus.com
emailAddress_max                = 64

[ v3_ca ]
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid:always,issuer
basicConstraints = critical,CA:true

[ v3_intermediate_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, nonRepudiation, digitalSignature, cRLSign, keyCertSign,certSign
extendedKeyUsage = OCSPSigning,serverAuth,clientAuth,timeStamping,codeSigning,emailProtection

[ usr_cert ]
authorityInfoAccess = OCSP;URI:http://'$(hostname -f)':'$OCSP_SERVER_PORT'

[ v3_OCSP ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = OCSPSigning

trustList=2.16.840.1.113730.1.900
# these four are already defined in my OpenSSL, but they're here for if you're using an older version:
businessCategory=2.5.4.15
jurisdictionOfIncorporationLocalityName=1.3.6.1.4.1.311.60.2.1.1
jurisdictionOfIncorporationStateOrProvinceName=1.3.6.1.4.1.311.60.2.1.2
jurisdictionOfIncorporationCountryName=1.3.6.1.4.1.311.60.2.1.3

' > $CA_ROOT_DIR/intermediate/ca.cnf

echo "`date +\"%F %T\"` [INFO] Creating root CA intermediate key"
echo "CARoot@123" > $CA_ROOT_DIR/intermediate/mypass.enc
openssl genrsa -des3 -passout file:$CA_ROOT_DIR/intermediate/mypass.enc -out $CA_ROOT_DIR/intermediate/private/intermediate.cakey.pem 4096

echo "`date +\"%F %T\"` [INFO] Creating intermediate CSR"
openssl req -new -sha256 -config $CA_ROOT_DIR/intermediate/ca.cnf -passin file:$CA_ROOT_DIR/intermediate/mypass.enc  -key $CA_ROOT_DIR/intermediate/private/intermediate.cakey.pem -out $CA_ROOT_DIR/intermediate/csr/intermediate.csr.pem

echo "`date +\"%F %T\"` [INFO] Sign and generate immediate CA certificate"
openssl ca -config $CA_ROOT_DIR/ca.cnf -extensions v3_intermediate_ca -days 2650 -notext -batch -passin file:$CA_ROOT_DIR/mypass.enc -in $CA_ROOT_DIR/intermediate/csr/intermediate.csr.pem -out $CA_ROOT_DIR/intermediate/certs/intermediate.cacert.pem

echo "`date +\"%F %T\"` [INFO] Checking root CA database"
cat $CA_ROOT_DIR/index.txt

echo "`date +\"%F %T\"` [INFO] Creating root/intermediate chain certificate"
cat $CA_ROOT_DIR/intermediate/certs/intermediate.cacert.pem $CA_ROOT_DIR/certs/cacert.pem > $CA_ROOT_DIR/intermediate/certs/ca-chain.cert.pem

echo "`date +\"%F %T\"` [INFO] Verifying certificate chain"
openssl verify -CAfile $CA_ROOT_DIR/certs/cacert.pem $CA_ROOT_DIR/intermediate/certs/ca-chain.cert.pem


