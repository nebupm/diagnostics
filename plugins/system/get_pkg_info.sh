##METADATA-START
##@Command : get_pkg_info.sh
##@Description: Checks if a particular package ins installed or not and get some details
##@Help : Helps to see if we have up to date rpm package on the node.
##@Category :Stats
##METADATA-END

this_node=$(uname -n)
#PKG_NAME=pki-root-ca-cert
PKG_NAME=$@
if [[ -z $PKG_NAME ]]; then
	echo "$this_node,EMPTY,NA,NA,NA"
else
    read -a ARGS_ARRAY <<< $(echo ${PKG_NAME})
    for PKG in ${ARGS_ARRAY[@]}; do
        for repo in $(sudo nsenter -t 1 -n -m /bin/rpm -qa --qf "%{INSTALLTIME:date};%{NAME};%{VERSION}\n" | grep $PKG |sed -e s/\ /-/g);do
            INSTALL_DATE=$(echo $repo | awk -F ";" '{print $1}')
            NAME=$(echo $repo | awk -F ";" '{print $2}')
            VERSION=$(echo $repo | awk -F ";" '{print $NF}')
            echo "$this_node,$PKG,$NAME,$VERSION,$INSTALL_DATE"
        done
    done
fi