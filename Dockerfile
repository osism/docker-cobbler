FROM ubuntu:16.04
LABEL maintainer="Betacloud Solutions GmbH (https://www.betacloud-solutions.de)"

ENV DEBIAN_FRONTEND noninteractive
ENV VERSION ${VERSION:-2.8}

# NOTE: the release28 branch contains bugfixes for the 2.8 series not yet released
ENV BRANCH ${BRANCH:-release28}

ADD http://cobbler.github.io/loaders/elilo-3.8-ia64.efi /var/lib/cobbler/loaders/elilo-ia64.efi
ADD http://cobbler.github.io/loaders/grub-0.97-x86.efi /var/lib/cobbler/loaders/grub-x86.efi
ADD http://cobbler.github.io/loaders/grub-0.97-x86_64.efi /var/lib/cobbler/loaders/grub-x86_64.efi
ADD http://cobbler.github.io/loaders/menu.c32-4.02 /var/lib/cobbler/loaders/menu.c32
ADD http://cobbler.github.io/loaders/pxelinux.0-4.02 /var/lib/cobbler/loaders/pxelinux.0
ADD http://cobbler.github.io/loaders/yaboot-1.3.17 /var/lib/cobbler/loaders/yaboot
ADD https://cobbler.github.io/signatures/$VERSION.x/latest.json /var/lib/cobbler/distro_signatures.json

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        apache2 \
        atftpd \
        debmirror \
        fence-agents \
        git \
        ipmitool \
        isc-dhcp-server \
        libapache2-mod-wsgi \
        lsb-release \
        make \
        python-cheetah \
        python-django \
        python-netaddr \
        python-simplejson \
        python-urlgrabber \
        python-yaml \
        syslinux \
        xinetd \
    && rm -rf /var/lib/apt/lists/* \
    && a2enmod proxy \
    && a2enmod proxy_http \
    && git clone -b $BRANCH https://github.com/cobbler/cobbler /cobbler-repository

WORKDIR /cobbler-repository

RUN make install \
    && ln -s /etc/apache2/conf-available/cobbler.conf /etc/apache2/conf-enabled/cobbler.conf \
    && ln -s /etc/apache2/conf-available/cobbler_web.conf /etc/apache2/conf-enabled/cobbler_web.conf \
    && cp -r /var/lib/cobbler /var/lib/cobbler.docker \
    && cp -r /srv/www/cobbler /srv/www/cobbler.docker \
    && ln -s /srv/www/cobbler /var/www \
    && apt-get clean \
    && rm -rf \
        /tmp/* \
        /var/tmp/* \
        /cobbler-repository \
        /var/lib/cobbler/* \
        /srv/www/cobbler/*

WORKDIR /root

COPY files/cobbler.conf /etc/apache2/conf-available/cobbler.conf
COPY files/run.sh /run.sh

VOLUME ["/var/lib/cobbler", "/mnt", "/srv/www/cobbler"]

CMD ["/run.sh"]
