##METADATA-START
##@Command : node_uptime.sh
##@Description: Gets the server uptime
##@Help : Gets the server uptime
##@Category :Stats
##METADATA-END

uptime | awk -F "," '{print $1}'
exit 0