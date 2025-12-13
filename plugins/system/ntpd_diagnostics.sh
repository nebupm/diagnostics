##METADATA-START
##@Command : ntpd_diagnostics.sh
##@Description: Gets the ntp config and ntp offset.
##@Help : Helps understand the skew.
##@Category :Config and Stats
##METADATA-END

this_node=$(uname -n)
pattern="db-node|db[0-9]"

if [[ "$this_node" =~ $pattern ]]; then
    echo "Not-Applicable"
    exit 0
fi

NTP_CONF=$(sudo grep "^server" /etc/ntp.conf | awk '{print $2}' | grep 169)
if [[ $? -ne 0 ]]; then
    NTP_CONF=$(sudo grep "^server" /etc/ntp.conf |  awk '{print $2}' | tail -1)
fi

WHEN=$(sudo /usr/sbin/ntpq -p | grep "^*" | awk '{print $5}')
REACH=$(sudo /usr/sbin/ntpq -p | grep "^*" | awk '{print $7}')
OFFSETMS=$(sudo /usr/sbin/ntpq -p | grep "^*" | awk '{print $9}')

echo "NTP SERVER=$NTP_CONF, Offset(ms)=$OFFSETMS, Last polled(s)=$WHEN, Reach=$REACH(377 All good.)"
exit 0
