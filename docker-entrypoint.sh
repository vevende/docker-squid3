#!/bin/bash
set -e

# If fiven just argument
if [ "${1:0:1}" = '-' ]; then
  set -- gosu ${SQUID_USER} squid -f ${SQUID_CONFIG} "$@"
fi

# Run default arguments if you given squid
if [[ "${@}" == "squid" ]]; then
  set -- gosu ${SQUID_USER} squid -f ${SQUID_CONFIG} -NYCd 1
fi


if [[ ! -d ${SQUID_CACHE_DIR} ]]; then
  echo "Creating cache dir..."
  mkdir -p ${SQUID_CACHE_DIR}
  chown -R ${SQUID_USER}:${SQUID_USER} ${SQUID_CACHE_DIR}
}


if [[ ! -d ${SQUID_CACHE_DIR}/00 ]]; then
  echo "Initializing cache..."
  gosu ${SQUID_USER} squid -f ${SQUID_CONFIG} -N -z
fi

exec "$@"