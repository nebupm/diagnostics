##METADATA-START
##@Command : hprof_count.sh
##@Description: It get the count of hprof files on the node.
##@Help : It get the count of hprof files on the node.
##@Category :Stats
##METADATA-END

this_node=$(uname -n)
pattern="db|tomcat|webserver|pod[0-9]"

if [[ "$this_node" =~ $pattern ]]; then
    echo "Not-Applicable"
    exit 0
fi

HPROF_DIR=/var/log/jvm_logs
if [[ ! -d $HPROF_DIR ]]; then
    echo "$this_node,JFR_Logs=NA,GC_Logs=NA"
else
    echo "$this_node,JFR_Logs=$(ls $HPROF_DIR/*.jfr | wc -l | awk '{print $1}'),GC_Logs=$(ls $HPROF_DIR/*.log* | wc -l | awk '{print $1}')"
fi
exit 0
