#!/bin/sh

CONTAINER_IP=$1

sh clean.sh

mkdir ca
cd ca
mkdir ca.db.certs
touch ca.db.index
echo "1234" > ca.db.serial
cd ../

mkdir second-level-ca
cd second-level-ca
mkdir ca.db.certs
touch ca.db.index
echo "1234" > ca.db.serial
cd ../

mkdir expired-ca
cd expired-ca
mkdir ca.db.certs
touch ca.db.index
echo "1234" > ca.db.serial
cd ../

mkdir fake-ca
cd fake-ca
mkdir ca.db.certs
touch ca.db.index
echo "1234" > ca.db.serial
cd ../

mkdir second-level-ca-2
cd second-level-ca-2
mkdir ca.db.certs
touch ca.db.index
echo "1234" > ca.db.serial
cd ../

mkdir second-level-ca-alt1-common-name
cd second-level-ca-alt1-common-name
mkdir ca.db.certs
touch ca.db.index
echo "1234" > ca.db.serial
cd ../

mkdir second-level-ca-alt2-public-key
cd second-level-ca-alt2-public-key
mkdir ca.db.certs
touch ca.db.index
echo "1234" > ca.db.serial
cd ../

mkdir third-level-ca
cd third-level-ca
mkdir ca.db.certs
touch ca.db.index
echo "1234" > ca.db.serial
cd ../

mkdir server-certificate
mkdir attacker-certificate
mkdir alt1-common-name
mkdir alt2-expiration-date
mkdir alt3-public-key
mkdir alt4-expired-ca
mkdir fake-chain-of-trust
mkdir attacker-certificate-signed-by-altered-int-ca

# Root Certificate Authority's Certificate
openssl genrsa -out ca/ca.key 2048
openssl req -new -x509 -days 365 -key ca/ca.key -out ca/ca.pem \
-sha256 \
-subj "/C=it/ST=State/L=City/CN=Certificate Authority"

# Legit Server Certificate Request and CA Signing
openssl genrsa -out server-certificate/serverKey.pem 2048
openssl req -new -nodes -key server-certificate/serverKey.pem \
-sha256 \
-out server-certificate/serverCertificateRequest.pem \
-subj "/C=it/ST=State/L=City/CN=$CONTAINER_IP" \
-batch

openssl ca -config ca.conf -out server-certificate/serverCertificate.pem \
-in server-certificate/serverCertificateRequest.pem \
-batch

# Legit Server Certificate Request as Client and CA Signing
echo "unique_subject = no" > ca/ca.db.index.attr # Allow duplicate subjects to be signed by CA. In this case, the same subject wants to have a general SSL certificate and one for client authentication only.
openssl genrsa -out server-certificate/serverKeyAsClient.pem 2048
openssl req -new -nodes -key server-certificate/serverKeyAsClient.pem \
-sha256 \
-out server-certificate/serverCertificateRequestAsClient.pem \
-subj "/C=it/ST=State/L=City/CN=$CONTAINER_IP" \
-batch

openssl ca -config ca.conf -out server-certificate/serverCertificateAsClient.pem \
-in server-certificate/serverCertificateRequestAsClient.pem \
-extfile clientCertificateExtensions.conf \
-batch

# Intermediate Certificate Authority (Second Level)'s Certificate Signing Request and Root CA Signing of it,
# then Signing the Certificate Signing Request of the Server with the Intermediate Certificate
openssl genrsa -out second-level-ca/ca.key 2048
openssl req -new -nodes -key second-level-ca/ca.key \
-sha256 \
-out second-level-ca/intermediateCACertificateRequest.pem \
-subj "/C=it/ST=State/L=City/CN=Intermediate Certificate Authority" \
-batch

openssl ca -config ca.conf -out second-level-ca/ca.pem \
-in second-level-ca/intermediateCACertificateRequest.pem \
-extfile intermediateCAExtensions.conf \
-batch

openssl ca -config second-level-ca.conf -out server-certificate/serverCertificateSignedByIntermediate.pem \
-in server-certificate/serverCertificateRequest.pem \
-batch

touch server-certificate/serverCertificateSignedByIntermediate-withRootCAIntegrated.pem
touch second-level-ca/ca-chain-of-trust.pem
cat second-level-ca/ca.pem ca/ca.pem > second-level-ca/ca-chain-of-trust.pem
cat server-certificate/serverCertificateSignedByIntermediate.pem second-level-ca/ca-chain-of-trust.pem > server-certificate/serverCertificateSignedByIntermediate-withRootCAIntegrated.pem

# Attacker's Self Signed Root Certificate
openssl genrsa -out attacker-certificate/attackerKey.pem 2048

openssl req -new -x509 -days 365 -key attacker-certificate/attackerKey.pem \
-sha256 \
-out attacker-certificate/attackerCertificate.der \
-outform DER \
-subj "/C=it/ST=State/L=City/CN=False Server" \
-batch

# Fake Chain of Trust (Attacker uses a self signed certificate as Root Certificate Authority)
openssl genrsa -out fake-ca/ca.key 2048
openssl req -new -x509 -days 365 -key fake-ca/ca.key -out fake-ca/ca.pem \
-sha256 \
-subj '/C=it/ST=State/L=City/CN=Certificate Authority'

openssl req -new -nodes -key attacker-certificate/attackerKey.pem \
-sha256 \
-out fake-chain-of-trust/attackerCertificateRequest.pem \
-subj "/C=it/ST=State/L=City/CN=$CONTAINER_IP" \
-batch

openssl ca -config fake-ca.conf -out fake-chain-of-trust/attackerCertificate.pem \
-in fake-chain-of-trust/attackerCertificateRequest.pem \
-batch

# Second Intermediate CA (Still Second Level)
openssl genrsa -out second-level-ca-2/ca.key 2048
openssl req -new -nodes -key second-level-ca-2/ca.key \
-sha256 \
-out second-level-ca-2/intermediateCACertificateRequest.pem \
-subj "/C=it/ST=State/L=City/CN=Second Intermediate Certificate Authority" \
-batch

openssl ca -config ca.conf -out second-level-ca-2/ca.pem \
-in second-level-ca-2/intermediateCACertificateRequest.pem \
-extfile intermediateCAExtensions.conf \
-batch

openssl req -new -nodes -key attacker-certificate/attackerKey.pem \
-sha256 \
-out attacker-certificate-signed-by-altered-int-ca/attackerCertificateRequest.pem \
-subj "/C=it/ST=State/L=City/CN=$CONTAINER_IP" \
-batch

# Intermediate CA Alt 1
cp second-level-ca-2/ca.key second-level-ca-alt1-common-name/ca.key
openssl x509 -in second-level-ca-2/ca.pem \
-outform DER \
-out second-level-ca-2/ca.der

openssl x509 -in second-level-ca/ca.pem \
-outform DER \
-out second-level-ca/ca.der

~/.venv/mqtt-over-tls/bin/python3 scriptsToAlterCertificate/alterCommonName.py \
'second-level-ca-2/ca.der' \
'second-level-ca-alt1-common-name/ca.der' \
'second-level-ca/ca.der'

openssl x509 -in second-level-ca-alt1-common-name/ca.der \
-inform DER \
-out second-level-ca-alt1-common-name/ca.pem

openssl ca -config second-level-ca-alt1-common-name.conf -out attacker-certificate-signed-by-altered-int-ca/attackerCertificate-alt1.pem \
-in attacker-certificate-signed-by-altered-int-ca/attackerCertificateRequest.pem \
-batch

touch second-level-ca-alt1-common-name/ca-chain-of-trust.pem
cat second-level-ca-alt1-common-name/ca.pem ca/ca.pem > second-level-ca-alt1-common-name/ca-chain-of-trust.pem

# Intermediate CA Alt 2
cp second-level-ca-2/ca.key second-level-ca-alt2-public-key/ca.key

~/.venv/mqtt-over-tls/bin/python3 scriptsToAlterCertificate/alterPublicKey.py \
'second-level-ca/ca.der' \
'second-level-ca-alt2-public-key/ca.der' \
'second-level-ca-2/ca.der'

openssl x509 -in second-level-ca-alt2-public-key/ca.der \
-inform DER \
-out second-level-ca-alt2-public-key/ca.pem

openssl ca -config second-level-ca-alt2-public-key.conf -out attacker-certificate-signed-by-altered-int-ca/attackerCertificate-alt2.pem \
-in attacker-certificate-signed-by-altered-int-ca/attackerCertificateRequest.pem \
-batch

touch second-level-ca-alt2-public-key/ca-chain-of-trust.pem
cat second-level-ca-alt2-public-key/ca.pem ca/ca.pem > second-level-ca-alt2-public-key/ca-chain-of-trust.pem

# Convert Signed Server Certificate to .der (ASN.1 encoding) for alteration purposes
openssl x509 -in server-certificate/serverCertificate.pem \
-outform DER \
-out server-certificate/serverCertificate.der

# Alteration 1 - Changing the Common Name
~/.venv/mqtt-over-tls/bin/python3 scriptsToAlterCertificate/alterCommonName.py \
'server-certificate/serverCertificate.der' \
'alt1-common-name/attackerCertificate.der' \
'attacker-certificate/attackerCertificate.der'

# Alteration 2 - Expired Certificate
~/.venv/mqtt-over-tls/bin/python3 scriptsToAlterCertificate/alterExpirationDate.py

# Alteration 3 - Replacing the Public Key
~/.venv/mqtt-over-tls/bin/python3 scriptsToAlterCertificate/alterPublicKey.py \
'server-certificate/serverCertificate.der' \
'alt3-public-key/attackerCertificate.der' \
'attacker-certificate/attackerCertificate.der'

# Alteration 4 - Certificate signed by an Expired Certificate Authority Certificate
openssl x509 -in ca/ca.pem -out expired-ca/caCopy.der -outform DER
cp ca/ca.key expired-ca/ca.key
~/.venv/mqtt-over-tls/bin/python3 scriptsToAlterCertificate/alterCertificateAuthorityExpirationDate.py
openssl x509 -in expired-ca/ca.der -out expired-ca/ca.pem -inform DER

openssl req -new -nodes -key attacker-certificate/attackerKey.pem \
-sha256 \
-out alt4-expired-ca/attackerCertificateRequest.pem \
-subj "/C=it/ST=State/L=City/CN=$CONTAINER_IP" \
-batch

openssl ca -config expired-ca.conf -out alt4-expired-ca/attackerCertificate.pem \
-in alt4-expired-ca/attackerCertificateRequest.pem \
-batch

# Intermediate CA (Third Level)
openssl genrsa -out third-level-ca/ca.key 2048
openssl req -new -nodes -key third-level-ca/ca.key \
-sha256 \
-out third-level-ca/intermediateCACertificateRequest.pem \
-subj "/C=it/ST=State/L=City/CN=Third Level Intermediate Certificate Authority" \
-batch

openssl ca -config second-level-ca.conf -out third-level-ca/ca.pem \
-in third-level-ca/intermediateCACertificateRequest.pem \
-extfile intermediateCAExtensions.conf \
-batch

openssl ca -config third-level-ca.conf -out server-certificate/serverCertificateSignedByThirdLevelIntermediate.pem \
-in server-certificate/serverCertificateRequest.pem \
-batch

touch server-certificate/serverCertificateSignedByThirdLevelIntermediate-withRootCAIntegrated.pem
touch third-level-ca/ca-chain-of-trust.pem
cat third-level-ca/ca.pem second-level-ca/ca.pem ca/ca.pem > third-level-ca/ca-chain-of-trust.pem
cat server-certificate/serverCertificateSignedByThirdLevelIntermediate.pem third-level-ca/ca-chain-of-trust.pem > server-certificate/serverCertificateSignedByThirdLevelIntermediate-withRootCAIntegrated.pem

# For each Attacker Certificate, convert from .der to .pem for MQTT Library
openssl x509 -inform DER -in attacker-certificate/attackerCertificate.der -out attacker-certificate/attackerCertificate.pem
openssl x509 -inform DER -in alt1-common-name/attackerCertificate.der -out alt1-common-name/attackerCertificate.pem
openssl x509 -inform DER -in alt2-expiration-date/attackerCertificate.der -out alt2-expiration-date/attackerCertificate.pem
openssl x509 -inform DER -in alt3-public-key/attackerCertificate.der -out alt3-public-key/attackerCertificate.pem