##METADATA-START
##@Command : spring_ver.sh
##@Description: Gets the latest installed spring framework version on the node.
##@Help : Gets the latest installed spring framework version on the node.
##@Category :Stats
##METADATA-END

this_node=$(uname -n)
pattern="amq|activemq"
if [[ "$this_node" =~ $pattern ]]; then
    sudo ls -l /proc/*/fd | grep -Eo '\S+\/spring\S+jar' | uniq | grep spring-core
else
    echo "Not-Applicable"
fi
exit 0
