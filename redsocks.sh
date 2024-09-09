#!/bin/sh

if [ $# -eq 2 ]; then
    proxy_ip=$1
    proxy_port=$2
    sed_script="
        s|\${proxy_ip}|${proxy_ip}|;
        s|\${proxy_port}|${proxy_port}|;
    "
elif [ $# -eq 4 ]; then
    proxy_ip=$1
    proxy_port=$2
    proxy_username=$3
    proxy_password=$4
    sed_script="
        s|\${proxy_ip}|${proxy_ip}|;
        s|\${proxy_port}|${proxy_port}|;
        s|\${proxy_username}|${proxy_username}|;
        s|\${proxy_password}|${proxy_password}|;
	s|//login|login|;
	s|//password|password|;
    "
else
    echo "No proxy URL defined. Using default."
    proxy_ip=10.26.141.135
    proxy_port=3128
    sed_script="
        s|\${proxy_ip}|${proxy_ip}|;
        s|\${proxy_port}|${proxy_port}|;
    "
fi

echo "Creating redsocks configuration file using proxy ${proxy_ip}:${proxy_port}..."

sed -e "$sed_script" /etc/redsocks.tmpl > /tmp/redsocks.conf

echo "Generated configuration:"
cat /tmp/redsocks.conf

echo "Activating iptables rules..."
/usr/local/bin/redsocks-fw.sh start

pid=0

# SIGUSR1 handler
usr_handler() {
  echo "usr_handler"
}

# SIGTERM-handler
term_handler() {
    if [ $pid -ne 0 ]; then
        echo "Term signal catched. Shutdown redsocks and disable iptables rules..."
        kill -SIGTERM "$pid"
        wait "$pid"
        /usr/local/bin/redsocks-fw.sh stop
    fi
    exit 143; # 128 + 15 -- SIGTERM
}

# setup handlers
trap 'kill ${!}; usr_handler' SIGUSR1
trap 'kill ${!}; term_handler' SIGTERM

echo "Starting redsocks..."
/usr/local/bin/redsocks -c /tmp/redsocks.conf &
sleep 1s
/usr/local/bin/dnscrypt-proxy -config /config/dnscrypt-proxy.toml &
#/usr/local/bin/pdnsd --tcp -mto &
pid="$!"

# wait indefinetely
while true
do
    tail -f /dev/null & wait ${!}
done
