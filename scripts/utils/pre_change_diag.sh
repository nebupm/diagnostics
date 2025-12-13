#! /usr/bin/env bash

function initialise_paths(){
    THIS_UNIQ_ID=$$
    FULL_PATH=$(realpath $0)
    SCRIPTNAME=$(basename ${FULL_PATH})
    SCRIPTS_DIR=$(dirname $(dirname ${FULL_PATH}))
    DIAGNOSTICS_DIR=$(dirname ${SCRIPTS_DIR})
    DIAGNOSTIC_SCRIPT=${DIAGNOSTICS_DIR}/scripts/bin/run_diagnostics.sh
    LOG_DIR=${DIAGNOSTICS_DIR}/logs
    source ${DIAGNOSTICS_DIR}/scripts/lib/common_utils_functions.sh
    source ${DIAGNOSTICS_DIR}/scripts/lib/html_generator.sh
    emailid="nebu.mathews@oracle.com"
}

function execute_job(){
    region_name_list=$1
    shift
    run_command_on_regions $region_name_list $@
    wait $(jobs -lr | awk '{printf("%s ",$2)}')
    TMPCSVFILE=$(mktemp).csv
    for this_file in $(ls ${LOG_DIR}/${THIS_UNIQ_ID}_${INPUT_SCRIPT%.sh}.*); do
        grep -v -e "NA,NA,NA" -e "FAILED" -e ",$"  $this_file | awk -F "," '{ if ($2 == "NodeName") { printf("%s,%s,%s,%s,Status\n",$1,$2,$3,$4) } else { printf("%s,%s,%s,%s,%s\n",$1,$5,$3,$4,$NF)}}'
        rm -f $this_file
    done | sort | uniq |  tee -a $TMPCSVFILE

    head -1 $TMPCSVFILE > $RESULT_CSV_FILE
    grep -v "NodeName" $TMPCSVFILE >> $RESULT_CSV_FILE
    
    HEADERFILE=$(mktemp).html
    FOOTERFILE=$(mktemp).html
    SUBJECT="[$(date)] ${INPUT_SCRIPT%.sh}"
    write_html_header "${INPUT_SCRIPT%.sh} status" "Detailed table with ${INPUT_SCRIPT%.sh}." >$HEADERFILE
    
    write_html_footer > $FOOTERFILE
    TMPHTML=${RESULT_CSV_FILE%.csv}.html
    csv2html $RESULT_CSV_FILE $HEADERFILE $FOOTERFILE > $TMPHTML
    if [[ ! -z $emailid ]]; then
        send_email $emailid "$SUBJECT" $TMPHTML $RESULT_CSV_FILE
    fi
    echo "CSV Results generated in $RESULT_CSV_FILE"
    echo "HTML Results generated in $TMPHTML"
    return 0
}


#########################################################################################
#   Start
#########################################################################################
initialise_paths

if [[ $# -eq 0 ]]; then
    echo "Usage:"
    echo "Example: "
    echo "  $SCRIPTNAME ltn"
    echo "  $SCRIPTNAME ltn,brs,fra"
    exit 1
fi
input_regions=$1
shift
INPUT_SCRIPT_LIST=$(echo "hub_manager_status.sh:--node=hub1,hc_status.sh:,check_extnd_status_apps.sh:--node=hub1" | tr ',' ' ')
for input_data in $INPUT_SCRIPT_LIST; do
    INPUT_SCRIPT=$(echo $input_data | awk -F ":" '{print $1}')
    node_details=$(echo $input_data | awk -F ":" '{print $NF}')
    RESULT_CSV_FILE=${LOG_DIR}/${THIS_UNIQ_ID}_${INPUT_SCRIPT%.sh}.csv
    execute_job $input_regions $node_details $@
done
exit $?
