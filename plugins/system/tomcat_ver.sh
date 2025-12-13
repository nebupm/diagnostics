##METADATA-START
##@Command : tomcat_ver.sh
##@Description: Gets the latest installed tomcat version on the node.
##@Help : Gets the latest installed tomcat version on the node.
##@Category :Stats
##METADATA-END

this_node=$(uname -n)
pattern="tomcat|appli|webserver|node[0-9]"
if [[ "$this_node" =~ $pattern ]]; then
    sudo java -cp /usr/share/tomcat/lib/catalina.jar org.apache.catalina.util.ServerInfo | grep "Server version"
else
    echo "Not-Applicable"
fi
exit 0
