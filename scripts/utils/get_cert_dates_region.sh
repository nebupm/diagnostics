#! /usr/bin/env bash

# shellcheck disable=SC2086
# shellcheck disable=SC2046
# shellcheck disable=SC1091
# shellcheck disable=SC2068
# shellcheck disable=SC2231

function initialise(){
    THIS_UNIQ_ID=$$
    FULL_PATH=$(realpath $0)
    SCRIPTNAME=$(basename ${FULL_PATH})
    SCRIPTS_DIR=$(dirname $(dirname ${FULL_PATH}))
    DIAGNOSTICS_DIR=$(dirname ${SCRIPTS_DIR})
    # shellcheck disable=SC2034
    DIAGNOSTIC_SCRIPT=${DIAGNOSTICS_DIR}/scripts/bin/run_diagnostics.sh
    LOG_DIR=${DIAGNOSTICS_DIR}/logs
    INPUT_SCRIPT=$1
    # shellcheck disable=SC2034
    RESULT_CSV_FILE=${LOG_DIR}/${THIS_UNIQ_ID}_${INPUT_SCRIPT%.sh}.csv
    source ${DIAGNOSTICS_DIR}/scripts/lib/common_utils_functions.sh
    source ${DIAGNOSTICS_DIR}/scripts/lib/html_generator.sh
    # shellcheck disable=SC2034
    EMAILIDS="nebu.mathews@oracle.com"
}

function parse_output_data(){
    # shellcheck disable=SC2034
    local input_arguments=$1
    local temp_csv_file
    temp_csv_file=$(mktemp).csv

    #Output Format
    #RegionName,NodeName,Plugin,Command,RESULT1,RESULT2,RESULT3,RESULT4,RESULT5,RESULT6
    #lin,hub1,system,get_host_cert_dates.sh,lin1-vbstudio-prod-hub-3,,,/etc/pki/ca-trust/source/anchors/transitional-missioncontrol-root-ca.crt,22/Aug/2016,20/Aug/2026
    #lin,hub1,system,get_host_cert_dates.sh,lin1-vbstudio-prod-hub-3,,,/etc/pki/ca-trust/source/anchors/missioncontrol-root-ca.crt,22/Aug/2016,20/Aug/2026
    #lin,hub1,system,get_host_cert_dates.sh,lin1-vbstudio-prod-hub-3,,,/etc/pki/ca-trust/source/anchors/pki-eu-milan-1-ad1-root-ca-active.crt,3/Jun/2021,2/Jun/2026
    #lin,hub1,system,get_host_cert_dates.sh,lin1-vbstudio-prod-hub-3,,,/etc/pki/ca-trust/source/anchors/oraclecorp.crt,13/Jun/2014,12/Jun/2044
    #lin,hub1,system,get_host_cert_dates.sh,lin1-vbstudio-prod-hub-3,,,/etc/pki/ca-trust/source/anchors/pki-eu-milan-1-ad1-root-ca.crt,3/Jun/2021,2/Jun/2026
    for this_file in ${LOG_DIR}/${THIS_UNIQ_ID}_${INPUT_SCRIPT%.sh}.*; do
        grep -v -e "NA,NA,NA" -e "FAILED" -e ",$"  $this_file | awk -F "," '{ if ($2 == "NodeName") { printf("%s,%s,%s,%s,Cert_type,RPM_Version,FileName,Valid_From,Valid_Until\n",$1,$2,$3,$4) } else {printf("%s,%s,%s,%s,%s,%s,%s,%s,%s\n",$1,$5,$3,$4,$6,$7,$8,$9,$NF)}}'
        rm -f $this_file
    done | sort | uniq > $temp_csv_file
    local subject
    subject="[$(date)] Certificate Validity Report. Region : ${input_arguments^^}"
    local html_msg1
    html_msg1="Certificate Validity for each region." 
    local html_msg2
    html_msg2="This show all the certs available on the vm."
    render_email_message $temp_csv_file "$subject" "$html_msg1" "$html_msg2"
    return $?
}

function printusage(){
    echo "Usage:"
    echo "Example: "
    echo "  $SCRIPTNAME ltn"
    echo "  $SCRIPTNAME ltn psm"
    echo "  $SCRIPTNAME ltn all"
    echo "  $SCRIPTNAME ltn,brs,fra"
    echo "  $SCRIPTNAME ltn,brs,fra psm"
    echo "  $SCRIPTNAME ltn,brs,fra all"
    exit 1
}

#########################################################################################
#   Start
#########################################################################################
initialise "get_host_cert_dates.sh"
if [[ $# -eq 0 ]]; then
    printusage
fi
regions=$1
case "${2,,}" in
    all) nodes="--node=primarypod,psmpod";;
    psm) nodes="--node=psmpod";;
    *) nodes="--node=primarypod";;
esac
shift;shift
run_command_on_regions $regions $nodes $@
wait $(jobs -lr | awk '{printf("%s ",$2)}')
parse_output_data $regions $@
exit $?