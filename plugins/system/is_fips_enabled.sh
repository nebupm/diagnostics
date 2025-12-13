##METADATA-START
##@Command : is_fips_enabled.sh
##@Description: Checks if fips is enabled in the VM.
##@Help : FIPS status check.
##@Category :Status Check
##METADATA-END

this_node=$(uname -n)
pattern="db"
if [[ $this_node =~ $pattern ]]; then
    echo "$this_node,NA"
    exit 0
fi

if [[ ! -f /proc/sys/crypto/fips_enabled ]]; then 
    echo "$this_node,NO-FILE(FIPS-NOT-ENABLED)"
    exit 0
fi

isenabled=$(cat /proc/sys/crypto/fips_enabled)
if [[ $isenabled -eq 1 ]]; then 
    echo "$this_node,FIPS-ENABLED($isenabled)"
else 
    echo "$this_node,FIPS-NOT-ENABLED($isenabled)"
fi
