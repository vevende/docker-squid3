#!/bin/bash
set -e

# If given just arguments, treat as squid {options}
if [ "${1:0:1}" = '-' ]; then
  set -- squid -f ${SQUID_CONFIG} "$@"
fi

# Run default arguments if you given squid
if [ "${@}" = 'squid' ]; then
  set -- squid -f ${SQUID_CONFIG} -NYCd 1
fi

if [ ! -f ${SQUID_SSL_DIR}/squid.crt ]; then
  echo -n "Create Self-Signed Root CA Certificate... "

  openssl req -new -batch -newkey rsa:2048 -sha256 -days 365 \
    -nodes -x509 \
    -extensions v3_ca \
    -keyout ${SQUID_SSL_DIR}/squid.key -out ${SQUID_SSL_DIR}/squid.crt
  
  echo "[Done]"
  
  echo -n "Create a DER-encoded certificate to import into user's browsers... "

  openssl x509 -in ${SQUID_SSL_DIR}/squid.crt -outform DER -out ${SQUID_SSL_DIR}/squid.der

  echo "[Done]"

  echo "DER-encoded certificate location:  ${SQUID_SSL_DIR}/squid.der"

  chown ${SQUID_USER}:${SQUID_USER} -R ${SQUID_SSL_DIR}
fi

# Initializing SSL db

echo -n "Initialization SSL db... "

rm -rf /var/lib/ssl_db
/usr/local/lib/squid/ssl_crtd -c -s /var/lib/ssl_db >/dev/null 2>&1
chown ${SQUID_USER}:${SQUID_USER} -R /var/lib/ssl_db

echo "[Done]"

if [ ! -d ${SQUID_CACHE_DIR} ]; then
  echo -n "Create cache directory... "
  mkdir -p ${SQUID_CACHE_DIR}
  chown ${SQUID_USER}:${SQUID_USER} -R ${SQUID_CACHE_DIR}
  echo "[Done]"
fi

if [ ! -d ${SQUID_CACHE_DIR}/00 ]; then
  echo -n "Initialize cache directory... "
  squid -f ${SQUID_CONFIG} -N -z
  echo "[Done]"
fi

exec "$@"
