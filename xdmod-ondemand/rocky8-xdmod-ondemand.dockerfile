ARG BASE_IMAGE_PLATFORM
ARG XDMOD_IMAGE
FROM --platform=${BASE_IMAGE_PLATFORM} ${XDMOD_IMAGE}

LABEL description="The XDMoD OnDemand image used in our CI builds or local testing."

ARG XDMOD_ONDEMAND_GITHUB_TAG
ARG XDMOD_ONDEMAND_RPM
ARG XDMOD_GITHUB_TAG
ARG XDMOD_GITHUB_USER
ARG XDMOD_ONDEMAND_GITHUB_USER

ENV TERM=xterm-256color
ENV XDMOD_TEST_MODE=fresh_install

#RUN dnf install -y https://github.com/ubccr/xdmod-ondemand/releases/download/${XDMOD_ONDEMAND_GITHUB_TAG}/${XDMOD_ONDEMAND_RPM}

RUN dnf clean all
RUN rm -rf /var/cache/dnf

#RUN git clone --branch=${XDMOD_GITHUB_TAG} --depth=1 "https://github.com/${XDMOD_GITHUB_USER}/xdmod.git" /root/xdmod
#RUN git clone --branch=${XDMOD_ONDEMAND_GITHUB_TAG} --depth=1 "https://github.com/${XDMOD_ONDEMAND_GITHUB_USER}/xdmod-ondemand.git" /root/xdmod-ondemand
WORKDIR /root

#RUN git clone -b xdmod11.0 https://github.com/ubccr/xdmod.git /root/xdmod
# RUN git clone https://github.com/ubccr/xdmod-ondemand.git /root/xdmod-ondemand
RUN git clone -b main --depth=1 https://github.com/ShixinWu16/xdmod-ondemand /root/xdmod-ondemand && \
    git clone -b xdmod11.0 --depth=1 https://github.com/ShixinWu16/xdmod /root/xdmod && \
    ln -s ~/xdmod-ondemand/ ~/xdmod/open_xdmod/modules/ondemand

COPY entrypoint.sh /root/xdmod-ondemand/tests/scripts/entrypoint.sh

WORKDIR /root/xdmod

RUN composer install

RUN /root/bin/buildrpm xdmod ondemand

# Once the `aaronweeden:use-new-docker-container` branch is merged into ${XDMOD_ONDEMAND_GITHUB_TAG}, this line will no longer be needed:
# Not needed for 11.0 but needed for 10.5.0
# RPMS not out for 11.0

# RUN wget -nv -O /root/xdmod-ondemand/tests/scripts/bootstrap.sh https://raw.githubusercontent.com/aaronweeden/xdmod-ondemand/use-new-docker-container/tests/scripts/bootstrap.sh
RUN dnf install -y ~/rpmbuild/RPMS/noarch/xdmod*.rpm
ENTRYPOINT [ "/root/xdmod-ondemand/tests/scripts/entrypoint.sh" ]

WORKDIR /root