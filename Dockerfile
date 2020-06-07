# Redsocks docker image.

FROM debian:jessie

MAINTAINER Nicolas Carlier <https://github.com/ncarlier>

ENV DEBIAN_FRONTEND noninteractive

ENV DOCKER_NET ""

# Install packages
RUN apt-get update && apt-get install -y redsocks iptables
RUN apt-get install -y apt-utils debconf-utils dialog
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN echo "resolvconf resolvconf/linkify-resolvconf boolean false" | debconf-set-selections
RUN apt-get update
RUN apt-get install -y resolvconf
RUN apt-get install -y pdnsd

# Copy configuration files...
COPY redsocks.tmpl /etc/redsocks.tmpl
COPY whitelist.txt /etc/redsocks-whitelist.txt
COPY redsocks.sh /usr/local/bin/redsocks.sh
COPY redsocks-fw.sh /usr/local/bin/redsocks-fw.sh
COPY pdnsd.conf /etc/pdnsd.conf

RUN chmod +x /usr/local/bin/*

ENTRYPOINT ["/usr/local/bin/redsocks.sh"]
