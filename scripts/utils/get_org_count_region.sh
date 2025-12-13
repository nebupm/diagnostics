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
    #RegionName,NodeName,Plugin,Command,RESULT1,RESULT2,RESULT3,RESULT4,RESULT5
    #kix,hub1,devcs,get_org_count.sh,kix1-vbstudio-prod-hub-5,Native,6,2,4
    #sin,hub1,devcs,get_org_count.sh,sin1-vbstudio-prod-hub-3,Native,80,37,43
    #syd,hub1,devcs,get_org_count.sh,syd1-vbstudio-prod-hub-3,Native,167,87,80
    #xsp,hub1,devcs,get_org_count.sh,xsp1-vbstudio-prod-5-hub-3,Built-On,2,0,2
    for this_file in ${LOG_DIR}/${THIS_UNIQ_ID}_${INPUT_SCRIPT%.sh}.*; do
        grep -v -e "NA$" -e "FAILED" -e ",$"  $this_file | awk -F "," '{ if ($2 == "NodeName") { printf("%s,%s,%s,%s,Pod_Type,Org_Count,Shell_Enabled,Shell_Not_Enabled\n",$1,$2,$3,$4) } else {printf("%s,%s,%s,%s,%s,%s,%s,%s\n",$1,$5,$3,$4,$6,$7,$8,$9)}}'
        rm -f $this_file
    done | sort | uniq > $temp_csv_file
    local subject
    subject="[$(date)] VBS Org Project Count Report. Region : ${input_arguments^^}"
    local html_msg1
    html_msg1="Project Count per Org. Total Orgs = $(grep -v "RegionName" $temp_csv_file| awk -F "," '{print $7}' | paste -sd+ | bc)"
    local html_msg2
    html_msg2="Detailed table with project count per org in a region. This gives an indication of the number of customers actively using VBS per region."
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
initialise "get_org_count.sh"
if [[ $# -eq 0 ]]; then
    printusage
fi
regions=$1
case "${2,,}" in
    all) nodes="--node=hub1,psmhub1";;
    psm) nodes="--node=psmhub1";;
    *) nodes="--node=hub1";;
esac
shift;shift
run_command_on_regions $regions $nodes "--args=yes" $@
wait $(jobs -lr | awk '{printf("%s ",$2)}')
parse_output_data $regions $@
exit $?