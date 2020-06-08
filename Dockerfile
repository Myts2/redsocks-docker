# Compile redsocks 
FROM alpine AS redsocks
RUN mkdir /tmp/redsocks
WORKDIR /tmp/redsocks
RUN apk add gcc musl-dev linux-headers libevent-dev git make
RUN git clone https://github.com/darkk/redsocks "/tmp/redsocks"
RUN make ENABLE_STATIC=true
# Compile dnscrypt
FROM golang:alpine as dnscrypt
ENV RELEASE_TAG 2.0.42
RUN apk --no-cache add git && \
    git clone https://github.com/DNSCrypt/dnscrypt-proxy /go/src/github.com/DNSCrypt/ && \
    cd /go/src/github.com/DNSCrypt/dnscrypt-proxy && \
    git checkout tags/${RELEASE_TAG} && \
    CGO_ENABLED=0 GOOS=linux go install -a -ldflags '-s -w -extldflags "-static"' -v ./...

# Main docker
FROM frolvlad/alpine-glibc 
RUN mkdir -p /var/cache/pdnsd
RUN apk add --no-cache libevent iptables
COPY --from=redsocks /tmp/redsocks/redsocks  /usr/local/bin/redsocks
COPY --from=dnscrypt /go/bin/dnscrypt-proxy /usr/local/bin/dnscrypt-proxy

COPY redsocks.tmpl /etc/redsocks.tmpl
COPY whitelist.txt /etc/redsocks-whitelist.txt
COPY redsocks.sh /usr/local/bin/redsocks.sh
COPY redsocks-fw.sh /usr/local/bin/redsocks-fw.sh
COPY dnscrypt-proxy.toml /config/
RUN mkdir /blacklist/ ; touch /blacklist/blacklist.txt

RUN chmod +x /usr/local/bin/redsocks.sh
RUN chmod +x /usr/local/bin/redsocks-fw.sh
ENTRYPOINT ["/usr/local/bin/redsocks.sh"]
