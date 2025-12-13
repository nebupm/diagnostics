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
    EMAILIDS="..."
}

function parse_output_data(){
    # shellcheck disable=SC2034
    local input_arguments=$1
    local temp_csv_file
    temp_csv_file=$(mktemp).csv

    #Output Format
    #RegionName,NodeName,Plugin,Command,RESULT1,RESULT2
    #reg1,node1,devcs,check_db_lock.sh,reg1-prod-node-3,OK:Present(dbck.lock)
    #reg1,node2,devcs,check_db_lock.sh,reg1-prod-node-4,NOK:NOT_Present(dbck.lock)
    #reg1,legacynode1,devcs,check_db_lock.sh,reg1-prod-legacy-node-3,OK:Present(dbck.lock)
    #reg1,legacynode2,devcs,check_db_lock.sh,reg1-prod-legacy-node-4,NOK:NOT_Present(dbck.lock)
    for this_file in ${LOG_DIR}/${THIS_UNIQ_ID}_${INPUT_SCRIPT%.sh}.*; do
        grep -v -e "NA$" -e "FAILED" -e ",$"  $this_file | awk -F "," '{ if ($2 == "NodeName") { printf("%s,%s,%s,%s,Status\n",$1,$2,$3,$4) } else {printf("%s,%s,%s,%s,%s\n",$1,$5,$3,$4,$NF)}}'
        rm -f $this_file
    done | sort | uniq > $temp_csv_file
    local subject
    subject="[$(date)] Leftover DB Lock files Report. Region : ${input_arguments^^}"
    local html_msg1
    html_msg1="Check for DB.lock file"
    local html_msg2
    html_msg2="DB Patching file Check"
    render_email_message $temp_csv_file "$subject" "$html_msg1" "$html_msg2"
    return $?
}

function printusage(){
    echo "Usage:"
    echo "Example: "
    echo "  $SCRIPTNAME reg1"
    echo "  $SCRIPTNAME reg1 legacy"
    echo "  $SCRIPTNAME reg1 all"
    echo "  $SCRIPTNAME reg1,reg2,reg3"
    echo "  $SCRIPTNAME reg1,reg2,reg3 legacy"
    echo "  $SCRIPTNAME reg1,reg2,reg3 all"
    exit 1
}
#########################################################################################
#   Start
#########################################################################################
initialise check_db_lock.sh
if [[ $# -eq 0 ]]; then
    printusage
fi

regions=$1
case "${2,,}" in
    all) nodes="--node=node1,legacynode1";;
    legacy) nodes="--node=legacynode1";;
    *) nodes="--node=node1";;
esac
shift;shift
run_command_on_regions $regions $nodes $@
wait $(jobs -lr | awk '{printf("%s ",$2)}')
parse_output_data $regions $@
exit $?