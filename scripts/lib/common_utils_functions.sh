#! /usr/bin/env bash

# shellcheck disable=SC2068
# shellcheck disable=SC2086
# shellcheck disable=SC2125
# shellcheck disable=SC2128

########################################################################################################################
#This is kept here for any future reference. This is not used currently in any scripts.
#This following function will work if you have a bash array with regions names.
#Creation of array: read -a REGION_ARRAY <<< $(echo oci-native-ltn oci-native-brs ukgovlondon ukgovcardiff)
#function run_command(){
#    region_array_name=$1[@]
#    this_local_regions=("${!region_array_name}")
#    shift
#    for region in ${this_local_regions[@]}; do
#        OUTPUT_DATAFILE=${LOG_DIR}/${THIS_UNIQ_ID}_${INPUT_SCRIPT%.sh}.${region}
#        $DIAGNOSTIC_SCRIPT --region=${region} $@ --script=$INPUT_SCRIPT --output=$OUTPUT_DATAFILE --csv &
#    done
#}
#Usage of the above function.
#run_command REGION_ARRAY "--node=hub1" $@
########################################################################################################################

function WaitForNSeconds(){
    if [[ -z "$1" ]]; then
        ITER=1
    else
        ITER=$1
    fi
    for (( c=1; c<=ITER; c++ )); do sleep 1;  printf "*"; done
    echo ""
    return 0
}

function check_connection_to_region(){
    local this_region=$1
    if [[ $this_region =~ $LOCAL_POD_PATTERN ]]; then
        return 0
    fi
    if ! ssh "$this_region" "uname -a" > /dev/null 2>&1; then 
        echo "Login failure to $this_region. Exiting"
        return 1
    fi
    return 0
}

function run_command_on_regions(){
    local this_region_list=$(echo "$1" | tr ',' ' ')
    shift
    for this_local_region in $this_region_list; do
        check_connection_to_region $this_local_region
        OUTPUT_DATAFILE=${LOG_DIR}/${THIS_UNIQ_ID}_${INPUT_SCRIPT%.sh}.${this_local_region}
        $DIAGNOSTIC_SCRIPT --region="${this_local_region}" --script="$INPUT_SCRIPT" --output="$OUTPUT_DATAFILE" --csv $@
    done
}

#Commonly used Global variables.
export LOCAL_POD_PATTERN="oci-native-alm|earth|alm|lunar|solar|developer-us"
export SSH_CONFIG_FILE=(~/.ssh/earth ~/.ssh/lunar ~/.ssh/solar ~/.ssh/developer* ~/.ssh/oci-native-ossh*[!bak] ~/.ssh/*alm*)
export SSH_OPTIONS="-o StrictHostKeyChecking=no -o ConnectTimeout=30 -q"
export BANNER_MESSAGE="Use of the Oracle network and applications is intended solely for Oracle's authorized users"
