##METADATA-START
##@Command : tomcat_log.sh
##@Description: It will get the size of the tomcat log from the node.
##@Help : This will help clear the logs from the system in case there is space contention.
##@Category :Stats
##METADATA-END

this_node=$(uname -n)
pattern="web|access|appli"
if [[ "$this_node" =~ $pattern ]]; then
    TOMCAT_LOG_DIR=/var/log/tomcat
    echo "Tomcat=$(sudo du -sh $TOMCAT_LOG_DIR | awk '{print $1}'), #Large Files(GB): $(sudo du -sh $TOMCAT_LOG_DIR/* | grep "[0-9][G]" | wc -l), #Medium Files(MB): $(sudo du -sh $TOMCAT_LOG_DIR/* | grep "[0-9][M]" | wc -l), #Small Files(KB):$(sudo du -sh $TOMCAT_LOG_DIR/* | grep "[0-9][K]" | wc -l)"
else
    echo "Not-Applicable"
fi
exit 0
