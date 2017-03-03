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
  echo "Creating certificate..."
  apt update
  apt install openssl

  openssl req -new -batch -newkey rsa:2048 -sha256 -days 365 \
    -nodes -x509 \
    -extensions v3_ca \
    -keyout ${SQUID_SSL_DIR}/squid.key -out ${SQUID_SSL_DIR}/squid.crt

  chown ${SQUID_USER}:${SQUID_USER} -R ${SQUID_SSL_DIR}
fi

if [ ! -d ${SQUID_CACHE_DIR} ]; then
  echo "Creating cache dir..."
  mkdir -p ${SQUID_CACHE_DIR}
  chown ${SQUID_USER}:${SQUID_USER} -R ${SQUID_CACHE_DIR}
fi

if [ ! -d ${SQUID_CACHE_DIR}/00 ]; then
  echo "Initializing cache..."
  squid -f ${SQUID_CONFIG} -N -z
fi

exec "$@"
