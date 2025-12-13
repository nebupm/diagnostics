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
    #RegionName,NodeName,Plugin,Command,RESULT1,RESULT2
    #fra,amq1,devcs,hc_status.sh,fra1-vbstudio-prod-activemq-1,SUCCESS. The app seems to be running.
    #fra,amq2,devcs,hc_status.sh,fra1-vbstudio-prod-activemq-2,SUCCESS. The app seems to be running.
    #fra,hub1,devcs,hc_status.sh,fra1-vbstudio-prod-hub-1,SUCCESS. The app seems to be running.
    #fra,hub2,devcs,hc_status.sh,fra1-vbstudio-prod-hub-2,SUCCESS. The app seems to be running.
    for this_file in ${LOG_DIR}/${THIS_UNIQ_ID}_${INPUT_SCRIPT%.sh}.*; do
        grep -v -e "NA$" -e "FAILED" -e ",$"  $this_file | awk -F "," '{ if ($2 == "NodeName") { printf("%s,%s,%s,%s,Status\n",$1,$2,$3,$4) } else {printf("%s,%s,%s,%s,%s\n",$1,$5,$3,$4,$NF)}}'
        rm -f $this_file
    done | sort | uniq > $temp_csv_file
    local subject    
    subject="[$(date)] Health Check Report. Region : ${input_arguments^^}"
    local html_msg1
    html_msg1="VBS Node Health check status"
    local html_msg2
    html_msg2="Detailed table with checkStatus results."
    render_email_message $temp_csv_file "$subject" "$html_msg1" "$html_msg2"
    return $?
}

function printusage(){
    echo "Usage:"
    echo "Example: "
    echo "  $SCRIPTNAME ltn"
    echo "  $SCRIPTNAME ltn psm"
    echo "  $SCRIPTNAME ltn,brs,fra all"
    exit 1
}

#########################################################################################
#   Start
#########################################################################################
initialise "hc_status.sh"
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
