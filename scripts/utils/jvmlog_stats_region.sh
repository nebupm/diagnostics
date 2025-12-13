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
    # RegionName,NodeName,Plugin,Command,Result
    # ltn,hub1,system,hprof_count.sh,ltn1-vbstudio-prod-hub-1,JFR_Logs=2,GC_Logs=4
    # ltn,hub2,system,hprof_count.sh,ltn1-vbstudio-prod-hub-2,JFR_Logs=2,GC_Logs=5
    for this_file in ${LOG_DIR}/${THIS_UNIQ_ID}_${INPUT_SCRIPT%.sh}.*; do
        grep -v -e "NA,NA,NA" -e "FAILED" -e ",$"  $this_file | awk -F "," '{ if ($2 == "NodeName") { printf("%s,%s,%s,%s,JFR_Logs,GC_Logs\n",$1,$2,$3,$4) } else {split($6,jfr,"=");split($7,gc,"=");printf("%s,%s,%s,%s,%s,%s\n",$1,$5,$3,$4,jfr[2],gc[2])}}'
        rm -f $this_file
    done | sort | uniq > $temp_csv_file
    local subject    
    subject="[$(date)] JFR and GC logs count report. Region : ${input_arguments^^}"
    local html_msg1
    html_msg1="Get HPROF file count"
    local html_msg2
    html_msg2="JFR and GC logs count details"
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
initialise "hprof_count.sh"
if [[ $# -eq 0 ]]; then
    printusage
fi
regions=$1
case "${2,,}" in
    all) nodes="--node=hub,psmhub";;
    psm) nodes="--node=psmhub";;
    *) nodes="--node=hub";;
esac
shift;shift

run_command_on_regions $regions $nodes $@
wait $(jobs -lr | awk '{printf("%s ",$2)}')
parse_output_data $regions $@
exit $?
