##METADATA-START
##@Command : high_disk_usage.sh
##@Description: Gets the disks with more than THRESHOLD utilisation. Only local disks are considered.
##@Help : IF the usage breaches the threshold, it will be listed in the output. Take action by clearing up the files.
##@Category :Stats
##METADATA-END


THRESHOLD=75
RESULT=$(df -P | awk -v threshold_lim=$THRESHOLD '0+$5 >= threshold_lim {print}' | awk '{printf("Device: %s(%s) on %s\n",$1,$5,$NF)}')
if [[ -z $RESULT ]]; then 
    echo "No Threshold($THRESHOLD%) breach"
else 
    echo $RESULT
fi
exit 0