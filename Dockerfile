FROM ubuntu:16.04

ENV PATH=/usr/local/bin:${PATH} \
    LANG=C.UTF-8 \
    SQUID_VERSION=3.5.24 \
    SQUID_CONFIG=/etc/squid/squid.conf \
    SQUID_CACHE_DIR=/var/spool/squid \
    SQUID_LOG_DIR=/var/log/squid \
    SQUID_SSL_DIR=/etc/squid/ssl \
    SQUID_USER=proxy \
    GOSU_VERSION=1.7

RUN set -ex \
    && apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates wget \
    && rm -rf /var/lib/apt/lists/* \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true \
    && apt-get purge -y --auto-remove ca-certificates wget

RUN set -ex  \
    && buildDeps="build-essential make wget \
        libecap3-dev nettle-dev libgnutls28-dev libssl-dev libdbi-perl \
        libldap2-dev libpam0g-dev libdb-dev libsasl2-dev libcppunit-dev \
        libkrb5-dev comerr-dev libcap2-dev libexpat1-dev libxml2-dev \
        libnetfilter-conntrack-dev" \
    && apt-get update \
    && apt-get install -y openssl iputils-ping \
    && apt-get install -y --no-install-recommends $buildDeps \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /usr/src/squid \
    && wget -O squid3.tar.gz "http://www.squid-cache.org/Versions/v3/3.5/squid-${SQUID_VERSION}.tar.gz" \
    && tar -xzv -f squid3.tar.gz -C ./usr/src/ \
    && rm squid3.tar.gz \
    && cd /usr/src/squid-${SQUID_VERSION} \
    && ./configure \
        --build=x86_64-linux-gnu \
        --srcdir=. \
        --prefix=/usr/local \
        --includedir="\${prefix}/include" \
        --mandir="\${prefix}/share/man" \
        --infodir="\${prefix}/share/info" \
        --datadir="\${prefix}/share/squid" \
        --libexecdir="\${prefix}/lib/squid" \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --disable-maintainer-mode \
        --disable-dependency-tracking \
        --disable-arch-native \
        --enable-inline \
        --enable-async-io=8 \
        --enable-storeio="ufs,aufs,diskd,rock" \
        --enable-removal-policies="lru,heap" \
        --enable-delay-pools \
        --enable-cache-digests \
        --enable-icap-client \
        --enable-follow-x-forwarded-for \
        --enable-auth-basic="DB,fake,getpwnam,NCSA,NIS,PAM" \
        --enable-auth-digest="file" \
        --enable-auth-negotiate="kerberos,wrapper" \
        --enable-auth-ntlm="fake,smb_lm" \
        --enable-external-acl-helpers="file_userip,session,SQL_session,time_quota,unix_group,wbinfo_group"  \
        --enable-url-rewrite-helpers="fake"  \
        --enable-http-violations \
        --enable-eui  \
        --enable-esi  \
        --enable-icmp  \
        --enable-zph-qos  \
        --enable-ecap  \
        --disable-translation  \
        --with-swapdir=/var/spool/squid  \
        --with-logdir=/var/log/squid  \
        --with-pidfile=/var/run/squid.pid  \
        --with-filedescriptors=65536  \
        --with-large-files  \
        --with-default-user=${SQUID_USER}  \
        --enable-linux-netfilter \
            'CFLAGS=-g -O2 -fPIE -fstack-protector-strong -Wformat -Werror=format-security -Wall' \
            'LDFLAGS=-fPIE -pie -Wl,-z,relro -Wl,-z,now' \
            'CPPFLAGS=-D_FORTIFY_SOURCE=2' \
            'CXXFLAGS=-g -O2 -fPIE -fstack-protector-strong -Wformat -Werror=format-security' \
        --with-openssl \
        --enable-ssl  \
        --enable-ssl-crtd \
    && make -j$(nproc) \
    && make install \
    && ldconfig \
    && apt-get purge -y $buildDeps \
    && apt-mark manual $(apt-mark showauto) \
    && rm -rf /usr/src/squid

# Adding common certificates

RUN set -ex \
    && apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY squid.conf /etc/squid/squid.conf

RUN set -ex \
    && mkdir -p ${SQUID_SSL_DIR} \
    && chown ${SQUID_USER}:${SQUID_USER} -R /etc/squid \
    && chown ${SQUID_USER}:${SQUID_USER} -R ${SQUID_CACHE_DIR} \
    && chown ${SQUID_USER}:${SQUID_USER} -R ${SQUID_LOG_DIR}

COPY docker-entrypoint.sh /usr/sbin/

ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 2048 3128 3129 3130 3401 4827

CMD ["squid"]
