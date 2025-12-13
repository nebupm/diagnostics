##METADATA-START
##@Command : chef_ver.sh
##@Description: Gets the latest installed chef client version on the node.
##@Help : Gets the latest installed chef client version on the node.
##@Category :Stats
##METADATA-END

this_node=$(uname -n)

pattern="db"
if ! [[ "$this_node" =~ $pattern ]]; then
    chef_ver=$(cat /opt/chef/version-manifest.txt | head -1)
else
    chef_ver="NA"
fi
echo "$this_node,$chef_ver"
exit 0
