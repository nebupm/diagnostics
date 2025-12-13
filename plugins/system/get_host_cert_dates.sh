##METADATA-START
##@Command : get_host_cert_dates.sh
##@Description: Gets the certificate expiry dates.
##@Help : Helps us to decide when to renew the certs.
##@Category :Checks
##METADATA-END

function get_cert_data()
{
    file_type=$1
    file_filter=$2
    for ffiles in $(sudo find /etc/pki/ca-trust/source/anchors/ -name "$file_type" -print | grep -v -e tls -e httpd $file_filter); do
        tmp_file_cert_data=$(mktemp)".log"
        sudo openssl x509 -noout -subject -startdate -enddate -in $ffiles > $tmp_file_cert_data
        CERT_DATA=$(grep "subject" $tmp_file_cert_data | grep subject | awk -F "CN=" '{print $2}' | awk -F "/" '{print $1}'| awk -F " - " '{print $1}' | sed s/\ /-/g)
        VERSION=$(grep "subject" $tmp_file_cert_data | grep subject | awk -F "CN=" '{print $2}' | awk -F " - " '{print $NF}')
        FROM_DATE=$(grep notBefore  $tmp_file_cert_data | awk -F "=" '{printf("%s\n",$NF)}' | awk '{printf("%s/%s/%s\n",$2,$1,$4)}')
        TO_DATE=$(grep notAfter  $tmp_file_cert_data | awk -F "=" '{printf("%s\n",$NF)}' | awk '{printf("%s/%s/%s\n",$2,$1,$4)}')
        echo "$this_node,$CERT_DATA,$VERSION,$ffiles,$FROM_DATE,$TO_DATE@"
    done


}

this_node=$(uname -n)
pattern="db|dbnode"
if [[ "$this_node" =~ $pattern ]]; then
    echo "$this_node,NA,NA,NA,NA,NA,NA@"
    exit 0
fi

get_cert_data "*.crt" "-e legacy"
get_cert_data "*.pem" "-e objsign -e email"
