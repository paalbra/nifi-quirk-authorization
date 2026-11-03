#!/bin/sh
set -e

echobig() {
  echo -e "====\n=\n= $@\n=\n===="
}

echobig "Installing required packages"
apk update && apk add openjdk21 openssl

if [ ! -f /certs/ldap/ldap.key ] || [ ! -f /certs/ldap/ldap.crt ]; then
  echobig "Generating LDAP certificate and key (PEM, required by slapd)"
  /usr/bin/openssl req -nodes -new -x509 \
    -keyout /certs/ldap/ldap.key \
    -out /certs/ldap/ldap.crt \
    -subj "/CN=openldap"
fi

if [ ! -f /certs/nifi/server.keystore.jks ]; then
  echobig "Generating Nifi keypair directly in JKS keystore"
  /usr/bin/keytool -genkeypair \
    -alias nifi-server \
    -keyalg RSA \
    -keysize 2048 \
    -validity 3650 \
    -dname "CN=nifi" \
    -keystore /certs/nifi/server.keystore.jks \
    -storetype JKS \
    -storepass not-secret \
    -keypass not-secret \
    -ext "SAN=dns:nifi,dns:localhost,ip:127.0.0.1"
fi

if [ ! -f /certs/nifi/server.crt ]; then
  echobig "Exporting Nifi certificate as PEM"
  /usr/bin/keytool -exportcert \
    -rfc \
    -alias nifi-server \
    -keystore /certs/nifi/server.keystore.jks \
    -storetype JKS \
    -storepass not-secret \
    -file /certs/nifi/server.crt
fi

if [ ! -f /certs/nifi/truststore.ldap.jks ]; then
  echobig "Creating Nifi LDAP truststore"
  /usr/bin/keytool -importcert \
    -file /certs/ldap/ldap.crt \
    -alias 1 \
    -keystore /certs/nifi/truststore.ldap.jks \
    -storetype JKS \
    -storepass not-secret \
    -noprompt
fi

echobig "Listing certs files"
/usr/bin/find /certs -type f
echobig "Listing Nifi server JKS keystore"
/usr/bin/keytool -list -storepass not-secret -keystore /certs/nifi/server.keystore.jks
echobig "Listing Nifi LDAP truststore JKS"
/usr/bin/keytool -list -storepass not-secret -keystore /certs/nifi/truststore.ldap.jks

echobig "Done ..."
