# Compile pdnsd
FROM gcc AS pdnsd
RUN apt update && apt install libevent-dev git wget -y
RUN wget http://members.home.nl/p.a.rombouts/pdnsd/releases/pdnsd-1.2.9a-par.tar.gz
RUN mkdir /tmp/pdnsd
RUN tar -zxvf pdnsd-1.2.9a-par.tar.gz -C /tmp/pdnsd
WORKDIR /tmp/pdnsd/pdnsd-1.2.9a
RUN ./configure && make
# Compile redsocks 
FROM alpine AS redsocks
RUN mkdir /tmp/redsocks
WORKDIR /tmp/redsocks
RUN apk add gcc musl-dev linux-headers libevent-dev git make
RUN git clone https://github.com/darkk/redsocks "/tmp/redsocks"
RUN make ENABLE_STATIC=true
FROM frolvlad/alpine-glibc 
RUN mkdir -p /var/cache/pdnsd
RUN apk add --no-cache libevent
COPY --from=pdnsd /tmp/pdnsd/pdnsd-1.2.9a/src/pdnsd  /usr/local/bin/pdnsd
COPY --from=redsocks /tmp/redsocks/redsocks  /usr/local/bin/redsocks

COPY redsocks.tmpl /etc/redsocks.tmpl
COPY whitelist.txt /etc/redsocks-whitelist.txt
COPY redsocks.sh /usr/local/bin/redsocks.sh
COPY redsocks-fw.sh /usr/local/bin/redsocks-fw.sh
COPY pdnsd.conf /usr/local/etc/pdnsd.conf

RUN chmod +x /usr/local/bin/redsocks.sh
RUN chmod +x /usr/local/bin/redsocks-fw.sh
ENTRYPOINT ["/usr/local/bin/redsocks.sh"]
