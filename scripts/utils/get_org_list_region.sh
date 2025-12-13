#! /usr/bin/env bash

# shellcheck disable=SC2086
# shellcheck disable=SC2046
# shellcheck disable=SC1091
# shellcheck disable=SC2068
# shellcheck disable=SC2231
# shellcheck disable=SC2155

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
    #RegionName,NodeName,Plugin,Command,RESULT1,RESULT2,RESULT3,RESULT4
    #lin,hub1,devcs,get_org_list.sh,lin1-vbstudio-prod-hub-3,chivapv-instance-mborri-lin,idcs-6c734ef2788e4f1a93e753495f953ba3,E46A70E1F9514F188C2A164C570767D6
    #lin,hub1,devcs,get_org_list.sh,lin1-vbstudio-prod-hub-3,demo-viorinho-lin,idcs-0f15cab42e8642e285b6d76c5673267f,55D770A7865C48A4BDF15279C052C443
    #lin,hub1,devcs,get_org_list.sh,lin1-vbstudio-prod-hub-3,gestionemodulistica-fsandro-lin,idcs-c0dc00067cf74b5c9c3bd2878f4c3ab0,D6FDAE9F958F4535838D19F4C520FD60
    for this_file in ${LOG_DIR}/${THIS_UNIQ_ID}_${INPUT_SCRIPT%.sh}.*; do
        grep -v -e "NA,NA,NA" -e "FAILED" -e ",$"  $this_file | awk -F "," '{ if ($2 == "NodeName") { printf("%s,%s,%s,%s,Org_id,IDCS,Service_id\n",$1,$2,$3,$4) } else {printf("%s,%s,%s,%s,%s,%s,%s\n",$1,$5,$3,$4,$6,$7,$NF)}}'
        rm -f $this_file
    done | sort | uniq > $temp_csv_file
    local subject="[$(date)] ORG List Report. Region : ${input_arguments^^}"
    local html_msg1="Org List for each region. Total Orgs = $(grep -c -v "RegionName" $temp_csv_file)"
    local html_msg2="Detailed table with list of all the orgs in a region. This gives an indication of the number of customers per region."
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
initialise "get_org_list.sh"
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
run_command_on_regions $regions $nodes $@
wait $(jobs -lr | awk '{printf("%s ",$2)}')
parse_output_data $regions $@
exit $?