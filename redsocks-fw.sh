#!/bin/sh

##########################
# Setup the Firewall rules
##########################
fw_setup() {
  # First we added a new chain called 'REDSOCKS' to the 'nat' table.
  iptables -t nat -N REDSOCKS

  # Next we used "-j RETURN" rules for the networks we don’t want to use a proxy.
  while read item; do
      iptables -t nat -A REDSOCKS -d $item -j RETURN
  done < /etc/redsocks-whitelist.txt

  # Redirect all TCP traffic to redsocks and all dns traffic to internal dns.
  iptables -t nat -A REDSOCKS -p tcp -j REDIRECT --to-ports 12345
  iptables -t nat ! -d 114.114.114.114 -I REDSOCKS 1 -p udp --dport 53 -j DNAT --to-destination 127.0.0.1:5533


  # Every Traffic which is not the socks server as destination is getting redirected to redsocks.
  iptables --table nat --append OUTPUT ! --destination "$socksip" --jump REDSOCKS


}


##########################
# Clear the Firewall rules
##########################
fw_clear() {
  iptables-save | grep -v REDSOCKS | iptables-restore
  #iptables -L -t nat --line-numbers
  #iptables -t nat -D PREROUTING 2
}

case "$1" in
    start)
        echo -n "Setting REDSOCKS firewall rules..."
        fw_clear
        fw_setup
        echo "done."
        ;;
    stop)
        echo -n "Cleaning REDSOCKS firewall rules..."
        fw_clear
        echo "done."
        ;;
    *)
        echo "Usage: $0 {start|stop}"
        exit 1
        ;;
esac
exit 0

