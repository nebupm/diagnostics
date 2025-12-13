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
    local input_arg1=$1
    local input_arg2=$2
    local temp_csv_file
    temp_csv_file=$(mktemp).csv

    #Output Format
    #RegionName,NodeName,Plugin,Command,RESULT1,RESULT2,RESULT3,RESULT4,RESULT5,RESULT6,RESULT7,RESULT8
    #lhr,hub1,devcs,get_shell_org_stats.sh,lhr1-vbstudio-prod-hub-5,IAHLME,4869,iahlme-dev1-lner-lhr,4889,idcs-7d81c91f07e14c999b1b7d648e329306,true,17
    #lhr,hub1,devcs,get_shell_org_stats.sh,lhr1-vbstudio-prod-hub-5,EYAM,5789,eyam-dev3-vv567l-mpaasvbshsmpp-lhr,7691,idcs-f7c717404f1d427e8da83f57dfefaee0,false,1
    for this_file in ${LOG_DIR}/${THIS_UNIQ_ID}_${INPUT_SCRIPT%.sh}.*; do
        grep -v -e "NA$" -e "FAILED" -e ",$"  $this_file | awk -F "," '{ if ($2 == "NodeName") { printf("%s,%s,%s,%s,FA_Pod_Name,Org_Id,IDCS,Shell,Project_Count\n",$1,$2,$3,$4) } else {printf("%s,%s,%s,%s,%s,%s,%s,%s,%s\n",$1,$5,$3,$4,$6,$8,$10,$11,$12)}}'
        rm -f $this_file
    done | sort | uniq > $temp_csv_file
    local subject
    
    subject="[$(date)] VBS Org Details with Project Count Report. Region : ${input_arg1^^}"
    local html_msg1
    html_msg1="Full details of these orgs ${input_arg2^^}."
    local html_msg2
    html_msg2="Total FA pods = $(grep -c -v "RegionName" $temp_csv_file).<br>Total Projects = $(grep -v RegionName $temp_csv_file| awk -F "," '{print $NF}' | paste -sd+ | bc).<br>Total Shell Enabled Projects = $(grep -v -e RegionName -e false $temp_csv_file| awk -F "," '{print $NF}' | paste -sd+ | bc)."
    render_email_message $temp_csv_file "$subject" "$html_msg1" "$html_msg2"
    return $?
}

function printusage(){
    echo "Usage:"
    echo "Example: "
    echo "  $SCRIPTNAME ltn iahhme,eyam"
    exit 1
}

#########################################################################################
#   Start
#########################################################################################
initialise "get_shell_org_stats.sh"
if [[ $# -lt 3 ]]; then
    printusage
fi
regions=$1
shell_list=$2
shift;shift
run_command_on_regions $regions "--node=hub1,psmhub1" "--args=$shell_list" $@
wait $(jobs -lr | awk '{printf("%s ",$2)}')
parse_output_data $regions $shell_list $@
exit $?