##METADATA-START
##@Command : filesystem_usage.sh
##@Description: It will show the usage of the filesystem of your choice. Argument needed. No argument will give root partition.
##@Help : This will help understand the filesystem usage.
##@Category :Stats
##METADATA-END

this_node=$(uname -n)
pattern="dp-node|cp-node"
filesystem_name=$@
if [[ -z $filesystem_name ]]; then
    filesystem_name="root"
fi
if [[ "$this_node" =~ $pattern ]]; then
    result=$(sudo df -h | grep $filesystem_name)
    if [[ $? -ne 0 ]]; then
        echo "$this_node,$filesystem_name,NA,NA,NA"
    else
        echo $result | awk -v node=$this_node '{ printf("%s,%s,%s,%s,%s\n",node,$1,$2,$4,$5)}'
    fi
else
    echo "$this_node,$filesystem_name,NA,NA,NA"
fi
exit 0
