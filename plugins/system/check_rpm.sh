##METADATA-START
##@Command : check_rpm.sh
##@Description: Checks if a particular package ins installed or not.
##@Help : Helps to see if we have up to date rpm package on the node.
##@Category :Stats
##METADATA-END

this_node=$(uname -n)
#PKG_NAME=pki-root-ca-cert
PKG_NAME=$@
if [[ -z $PKG_NAME ]]; then
	echo "Empty $PKG_NAME"
else
    read -a ARGS_ARRAY <<< $(echo ${PKG_NAME})
    for PKG in ${ARGS_ARRAY[@]}; do
        RESULT=$(sudo nsenter -t 1 -n -m /bin/rpm -qva | grep $PKG)
        if [[ $? -ne 0 ]]; then
            STATUS="Not Installed"
        else
            STATUS=$RESULT
        fi
        echo "$PKG : $STATUS"
    done
fi