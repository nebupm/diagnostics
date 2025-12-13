##METADATA-START
##@Command : node_fqdn.sh
##@Description: Gets the node fqdn and internal ip
##@Help : Gets the node fqdn and internal ip
##@Category :Stats
##METADATA-END

this_node=$(uname -n)
pattern="*"
if [[ "$this_node" =~ $pattern ]]; then
    echo "Not-Applicable"
    exit 0
fi
fqdn_file=/opt/chef/data/metrics/chef-version-map-fetch.json
if sudo test -f $fqdn_file; then
    echo "$(/usr/sbin/ip a | grep inet | grep -v inet6 | grep  global | grep -v docker | awk '{print $2}' | awk -F "/" '{print $1}'),$(sudo jq -r ".metricData[0].dimensions.host" $fqdn_file),$(sudo jq -r ".instance_ocid" /opt/chef-es3-run/data/merged-metadata.json)"
else
    echo "$(/usr/sbin/ip a | grep inet | grep -v inet6 | grep  global | grep -v docker | awk '{print $2}' | awk -F "/" '{print $1}'),$(uname -n),NA"
fi