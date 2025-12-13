##METADATA-START
##@Command : backup_status.sh
##@Description: Checks the backup logs to see the status of backup.
##@Help : It goes through the last backup log and gets the status.
##@Category :Stats
##METADATA-END

this_node=$(uname -n)
pattern="logger|appli|fileserver"
if [[ "$this_node" =~ $pattern ]]; then
	TODAY=$(date "+%Y%m%d")
	failure_status=$(sudo grep -r "Backup finished" /var/log/backup/ | grep "$TODAY" | sort | awk -F "log:" '{print $NF}' | grep -v success)
	success_status=$(sudo grep -r "Backup finished" /var/log/backup/ | grep "$TODAY" | sort | awk -F "log:" '{print $NF}' | grep success | tail -1)
	if [[ ! -z $failure_status ]]; then
		echo "$this_node,Backup Failures:$failure_status"
	else
		echo "$this_node,$success_status"
	fi
else
	echo "$this_node,Not-Applicable"
fi
exit 0
