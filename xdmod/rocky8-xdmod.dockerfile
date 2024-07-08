ARG BASE_IMAGE_PLATFORM
ARG XDMOD_BASE_IMAGE
FROM --platform=${BASE_IMAGE_PLATFORM} ${XDMOD_BASE_IMAGE}

LABEL description="The main XDMoD image used in our CI builds or local testing."

ARG COMPOSER
ARG COMPOSER_ALLOW_SUPERUSER
ARG XDMOD_GITHUB_TAG
ARG XDMOD_GITHUB_USER

ENV TERM=xterm-256color
ENV XDMOD_REALMS=jobs,storage,cloud,resourcespecifications
ENV XDMOD_TEST_MODE=fresh_install

# We have some caches that we put in place for automated builds.
# This will copy them into place if they exist
COPY assets /tmp/assets
COPY bin /root/bin

# COPY assets/mariadb-server.cnf /etc/my.cnf.d/mariadb-server.cnf

# Generate SSL Key and Generate SSL Certificate
RUN openssl genrsa -rand /proc/cpuinfo:/proc/filesystems:/proc/interrupts:/proc/ioports:/proc/uptime 2048 > /etc/pki/tls/private/localhost.key && \
    /usr/bin/openssl req -new -key /etc/pki/tls/private/localhost.key -x509 -sha256 -days 365 -set_serial $RANDOM -extensions v3_req -out /etc/pki/tls/certs/localhost.crt -subj "/C=XX/L=Default City/O=Default Company Ltd" && \
    rm -rf /tmp/assets/mariadb-rpms /tmp/assets/mariadb-server.cnf /tmp/assets/mysql-server.cnf

WORKDIR /root
RUN mkdir -p /root/rpmbuild/RPMS/noarch && \
    git clone -b xdmod11.0 https://github.com/ShixinWu16/xdmod /root/xdmod
# RUN git clone --branch=${XDMOD_GITHUB_TAG} --depth=1 "https://github.com/${XDMOD_GITHUB_USER}/xdmod.git" /root/xdmod

WORKDIR /root/xdmod

RUN composer install &&  \
    /root/bin/buildrpm xdmod

WORKDIR /root
# Once the `ryanrath:xdmod11-php8` branch is merged into ${XDMOD_GITHUB_TAG}, this line will no longer be needed:
# RUN sed -i 's|rm -rf /var/lib/mysql && mkdir -p /var/lib/mysql||g' /root/xdmod/tests/ci/bootstrap.sh

RUN rm -rf /var/cache/yum /var/cache/dnf /root/bin/buildrpm /root/xdmod/assets/mariadb-rpms && \
    dnf clean all && \
    dnf install -y mysql && \
    chmod +x /root/xdmod/tests/ci/bootstrap.sh

CMD /root/xdmod/tests/ci/bootstrap.sh && \
     dnf clean all && \
     rm -rf /var/cache/yum /root/xdmod /var/cache/dnf /root/rpmbuild && \
     tail -f /dev/null
