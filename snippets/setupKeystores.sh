#!bin/sh

CERTIFICATES='certificates'

rm -rf keystores
mkdir keystores

# Generate TLS Certificates for Test Cases, in case it was not already done for other libraries tests
cd $CERTIFICATES
sh setupCertificates.sh $1
cd -

# Convert all test-case certificates into .p12 stores (PKCS12)
openssl pkcs12 -export \
-in $CERTIFICATES/server-certificate/serverCertificate.pem \
-inkey $CERTIFICATES/server-certificate/serverKey.pem \
-passout pass:hivemqStorePassword \
-name hivemq \
-out keystores/serverCertificate.p12

openssl pkcs12 -export \
-in $CERTIFICATES/server-certificate/serverCertificateSignedByIntermediate-withRootCAIntegrated.pem \
-inkey $CERTIFICATES/server-certificate/serverKey.pem \
-passout pass:hivemqStorePassword \
-name hivemq \
-out keystores/serverCertificateSignedByIntermediate.p12

openssl pkcs12 -export \
-in $CERTIFICATES/server-certificate/serverCertificateAsClient.pem \
-inkey $CERTIFICATES/server-certificate/serverKeyAsClient.pem \
-passout pass:hivemqStorePassword \
-name hivemq \
-out keystores/serverCertificateAsClient.p12

openssl pkcs12 -export \
-in $CERTIFICATES/attacker-certificate/attackerCertificate.pem \
-inkey $CERTIFICATES/attacker-certificate/attackerKey.pem \
-passout pass:hivemqStorePassword \
-name hivemq \
-out keystores/attackerCertificate.p12

openssl pkcs12 -export \
-in $CERTIFICATES/fake-chain-of-trust/attackerCertificate.pem \
-inkey $CERTIFICATES/attacker-certificate/attackerKey.pem \
-passout pass:hivemqStorePassword \
-name hivemq \
-out keystores/attackerCertificateFakeChainOfTrust.p12

openssl pkcs12 -export \
-in $CERTIFICATES/attacker-certificate-signed-by-altered-int-ca/attackerCertificate-alt1.pem \
-inkey $CERTIFICATES/attacker-certificate/attackerKey.pem \
-passout pass:hivemqStorePassword \
-name hivemq \
-out keystores/attackerCertificateAlteredIntCACommonName.p12

openssl pkcs12 -export \
-in $CERTIFICATES/attacker-certificate-signed-by-altered-int-ca/attackerCertificate-alt2.pem \
-inkey $CERTIFICATES/attacker-certificate/attackerKey.pem \
-passout pass:hivemqStorePassword \
-name hivemq \
-out keystores/attackerCertificateAlteredIntCAPublicKey.p12

openssl pkcs12 -export \
-in $CERTIFICATES/alt1-common-name/attackerCertificate.pem \
-inkey $CERTIFICATES/server-certificate/serverKey.pem \
-passout pass:hivemqStorePassword \
-name hivemq \
-out keystores/alteration1CommonName.p12

openssl pkcs12 -export \
-in $CERTIFICATES/alt2-expiration-date/attackerCertificate.pem \
-inkey $CERTIFICATES/server-certificate/serverKey.pem \
-passout pass:hivemqStorePassword \
-name hivemq \
-out keystores/alteration2ExpirationDate.p12

openssl pkcs12 -export \
-in $CERTIFICATES/alt3-public-key/attackerCertificate.pem \
-inkey $CERTIFICATES/attacker-certificate/attackerKey.pem \
-passout pass:hivemqStorePassword \
-name hivemq \
-out keystores/alteration3PublicKey.p12

openssl pkcs12 -export \
-in $CERTIFICATES/alt4-expired-ca/attackerCertificate.pem \
-inkey $CERTIFICATES/attacker-certificate/attackerKey.pem \
-passout pass:hivemqStorePassword \
-name hivemq \
-out keystores/alteration4ExpiredCA.p12

openssl pkcs12 -export \
-in $CERTIFICATES/server-certificate/serverCertificateSignedByThirdLevelIntermediate-withRootCAIntegrated.pem \
-inkey $CERTIFICATES/server-certificate/serverKey.pem \
-passout pass:hivemqStorePassword \
-name hivemq \
-out keystores/serverCertificateSignedByThirdLevelIntermediate.p12

# For each PKCS12, convert to JKS for HiveMQ
cd keystores

keytool -importkeystore \
-srckeystore serverCertificate.p12 -srcstoretype PKCS12 \
-destkeystore serverCertificate.jks -deststoretype JKS \
-srcstorepass hivemqStorePassword \
-deststorepass hivemqStorePassword

keytool -importkeystore \
-srckeystore serverCertificateSignedByIntermediate.p12 -srcstoretype PKCS12 \
-destkeystore serverCertificateSignedByIntermediate.jks -deststoretype JKS \
-srcstorepass hivemqStorePassword \
-deststorepass hivemqStorePassword

keytool -importkeystore \
-srckeystore serverCertificateAsClient.p12 -srcstoretype PKCS12 \
-destkeystore serverCertificateAsClient.jks -deststoretype JKS \
-srcstorepass hivemqStorePassword \
-deststorepass hivemqStorePassword

keytool -importkeystore \
-srckeystore attackerCertificate.p12 -srcstoretype PKCS12 \
-destkeystore attackerCertificate.jks -deststoretype JKS \
-srcstorepass hivemqStorePassword \
-deststorepass hivemqStorePassword

keytool -importkeystore \
-srckeystore attackerCertificateFakeChainOfTrust.p12 -srcstoretype PKCS12 \
-destkeystore attackerCertificateFakeChainOfTrust.jks -deststoretype JKS \
-srcstorepass hivemqStorePassword \
-deststorepass hivemqStorePassword

keytool -importkeystore \
-srckeystore attackerCertificateAlteredIntCACommonName.p12 -srcstoretype PKCS12 \
-destkeystore attackerCertificateAlteredIntCACommonName.jks -deststoretype JKS \
-srcstorepass hivemqStorePassword \
-deststorepass hivemqStorePassword

keytool -importkeystore \
-srckeystore attackerCertificateAlteredIntCAPublicKey.p12 -srcstoretype PKCS12 \
-destkeystore attackerCertificateAlteredIntCAPublicKey.jks -deststoretype JKS \
-srcstorepass hivemqStorePassword \
-deststorepass hivemqStorePassword

keytool -importkeystore \
-srckeystore alteration1CommonName.p12 -srcstoretype PKCS12 \
-destkeystore alteration1CommonName.jks -deststoretype JKS \
-srcstorepass hivemqStorePassword \
-deststorepass hivemqStorePassword

keytool -importkeystore \
-srckeystore alteration2ExpirationDate.p12 -srcstoretype PKCS12 \
-destkeystore alteration2ExpirationDate.jks -deststoretype JKS \
-srcstorepass hivemqStorePassword \
-deststorepass hivemqStorePassword

keytool -importkeystore \
-srckeystore alteration3PublicKey.p12 -srcstoretype PKCS12 \
-destkeystore alteration3PublicKey.jks -deststoretype JKS \
-srcstorepass hivemqStorePassword \
-deststorepass hivemqStorePassword

keytool -importkeystore \
-srckeystore alteration4ExpiredCA.p12 -srcstoretype PKCS12 \
-destkeystore alteration4ExpiredCA.jks -deststoretype JKS \
-srcstorepass hivemqStorePassword \
-deststorepass hivemqStorePassword

keytool -importkeystore \
-srckeystore serverCertificateSignedByThirdLevelIntermediate.p12 -srcstoretype PKCS12 \
-destkeystore serverCertificateSignedByThirdLevelIntermediate.jks -deststoretype JKS \
-srcstorepass hivemqStorePassword \
-deststorepass hivemqStorePassword
