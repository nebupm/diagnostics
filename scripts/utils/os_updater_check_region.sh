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
    emailid=""
}

function execute_job(){
    command=$1
    shift
    run_command_on_regions $command $@
    wait $(jobs -lr | awk '{printf("%s ",$2)}')

    ################################################################################
    # Output Data format
    ################################################################################
    # RegionName,NodeName,Plugin,Command,RESULT1,RESULT2,RESULT3
    # brs,hub1,system,os_updater_status.sh,ALL-OK,X86-64_OL7_20240403.02,X86-64_OL7_20240403.02_UEK6
    # ltn,hub1,system,os_updater_status.sh,ALL-OK,X86-64_OL7_20240403.02,X86-64_OL7_20240403.02_UEK6
    ################################################################################

    TMPCSVFILE=$(mktemp).csv
    for this_file in $(ls ${LOG_DIR}/${THIS_UNIQ_ID}_${INPUT_SCRIPT%.sh}.*); do
        grep -v -e "NA,NA,NA" -e "FAILED" -e ",$"  $this_file | awk -F "," '{ if ($2 == "NodeName") { printf("%s,%s,%s,%s,Status,Latest,Current\n",$1,$2,$3,$4) } else { printf("%s,%s,%s,%s,%s,%s,%s\n",$1,$5,$3,$4,$6,$7,$NF)}}'
        rm -f $this_file
    done | sort | uniq |  tee -a $TMPCSVFILE
    return
    head -1 $TMPCSVFILE > $RESULT_CSV_FILE
    grep -v "NodeName" $TMPCSVFILE >> $RESULT_CSV_FILE
    
    HEADERFILE=$(mktemp).html
    FOOTERFILE=$(mktemp).html
    SUBJECT="[$(date)] OSUpdater Report"
    write_html_header "OS Updater check status" "Detailed table with OS Updater versions. Current and Latest available version." >$HEADERFILE
    
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

INPUT_SCRIPT=os_updater_status.sh
RESULT_CSV_FILE=${LOG_DIR}/${THIS_UNIQ_ID}_${INPUT_SCRIPT%.sh}.csv

if [[ $# -eq 0 ]]; then
    echo "Usage:"
    echo "Example: "
    echo "  $SCRIPTNAME ltn"
    echo "  $SCRIPTNAME ltn,brs,fra"
    exit 1
fi

regions=$1
shift
execute_job $regions $@
exit $?
