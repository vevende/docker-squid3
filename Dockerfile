FROM ubuntu:16.04

ENV PATH /usr/local/bin:$PATH

ENV LANG C.UTF-8

RUN set -ex  \
    && buildDeps="build-essential make wget \
        libecap3-dev nettle-dev libgnutls28-dev libssl-dev libdbi-perl \
        libldap2-dev libpam0g-dev libdb-dev libsasl2-dev libcppunit-dev \
        libkrb5-dev comerr-dev libcap2-dev libexpat1-dev libxml2-dev \
        libnetfilter-conntrack-dev" \
    && apt-get update \
    && apt-get install -y $buildDeps --no-install-recommends \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /usr/src/squid \
    && wget -O squid3.tar.gz "http://www.squid-cache.org/Versions/v3/3.5/squid-3.5.24.tar.gz" \
    && tar -xzf /usr/src/squid -f squid3.tar.gz \
    && rm squid3.tar.gz
    && cd /usr/src/squid \
    && ./configure \
        --build=x86_64-linux-gnu \
        --prefix=/usr/local/squid \
        --includedir="\${prefix}/include" \
        --mandir="\${prefix}/share/man" \
        --infodir="\${prefix}/share/info" \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --libexecdir="\${prefix}/lib/squid3" \
        --srcdir=. \
        --disable-maintainer-mode \
        --disable-dependency-tracking \
        --disable-silent-rules BUILDCXXFLAGS="-g -O2 -fdebug-prefix-map=/${PKGBUILDDIR}=. -fPIE -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -Wl,-Bsymbolic-functions -fPIE -pie -Wl,-z,relro -Wl,-z,now -Wl,--as-needed" \
        --datadir=/usr/share/squid \
        --sysconfdir=/etc/squid \
        --libexecdir=/usr/lib/squid \
        --mandir=/usr/share/man \
        --enable-inline \
        --disable-arch-native \
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
        --with-default-user=proxy  \
        --enable-build-info="Ubuntu linux"  \
        --enable-linux-netfilter  \
        --with-default-user=proxy \
        --with-openssl \
        --enable-ssl  \
        --enable-ssl-crtd \
    && make -j$(nproc) \
    && make install \
    && ldconfig \
    && apt-get purge -y --auto-remove $buildDeps \
    && rm -rf /usr/src/squid 

COPY squid.conf /etc/squid/squid.conf

CMD ["squid"]
