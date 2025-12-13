#! /usr/bin/env bash

# shellcheck disable=SC2046
# shellcheck disable=SC2068
# shellcheck disable=SC2086
# shellcheck disable=SC2128
# shellcheck disable=SC2179
# shellcheck disable=SC2145
# shellcheck disable=SC2001


function initialise(){
    print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]"
    NODE_ARRAY=()
    PLUGIN_ARRAY=()
    REGION_ARRAY=()
    # This variable is used to decide if we need to use the input list from user or get a dynamic list of nodes per region.
    # It is initialised with the assumption that user is going to provide a static input.
    DYNAMIC_NODES_LIST=0
    rm -f $LOG_DIR/$THIS_UNIQ_ID"-command-output-"*".json"
    local b_version
    b_version=$(bash --version | awk -F "-" '/bash/{print $1}' | awk '{print $NF}')
    bash_version_pattern="5\.[0-9]"
    if ! [[ $b_version =~ $bash_version_pattern ]]; then
        print_info_message "You have bash $b_version installed. You will need atleast version 5 and above."
        exit 1
    fi
    VALID_NODE_PATTERN="instance|pod|web|activemq|control|all|controlplane|dataplane|region|developer|test"
    HELP_OPTION_PATTERN="^[-]+"
}

function parse_inputs_no_options(){
    local this_option=$1
    print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME] Option:${this_option}" >&2
    case $this_option in
        d | debug) enable_debug ;;
        j | json) enable_json_output ;;
        c | csv) enable_csv_output ;;
        x | html) enable_html_output ;;
        v | version) show_version ;;
        P | listplugins) listplugins;;
        S | listscripts) listscripts;;
        R | listregions) listregions;;
    esac
}
function parse_inputs(){
    #optstring=":PSRGhdjcva-:g:r:n:p:s:N:o:"
    optstring=":PSRhdjxcva-:g:r:n:p:s:N:o:G:"
    while getopts ${optstring} OPT; do
        # Code Borrowed from [support long options: https://stackoverflow.com/a/28466267/519360]
        if [ "$OPT" = "-" ]; then   # long option: reformulate OPT and OPTARG
            OPT="${OPTARG%%=*}"       # extract long option name
            OPTARG="${OPTARG#$OPT}"   # extract long option argument (may be empty)
            OPTARG="${OPTARG#=}"      # if long option argument, remove assigning `=`
        fi
        case "$OPT" in
            h | help)  print_usage ;;
            d|j|c|x|v|P|S|R|debug|json|csv|html|version|listplugins|listscripts|listregions) parse_inputs_no_options $OPT ;;
            G | listgeos)
                print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME][listgeos:$OPTIND]: Option ${OPT} Argument: $OPTARG" >&2
                parse_list_geos_option_input "$OPTARG"
                ;;
            o | output)
                print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME][output:$OPTIND]: Option ${OPT} Argument: $OPTARG" >&2
                if [[ -z "$OPTARG" ]] || [[ "$OPTARG" =~ $HELP_OPTION_PATTERN ]]; then
                    print_option_o_usage
                    exit 2
                fi
                OUTPUT_FILE="${OPTARG/#\~/$HOME}"
                print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME][output:$OPTIND]: Option ${OPT} OUTPUT_FILE: $OUTPUT_FILE" >&2
                ;;
            N | listnodes)
                print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME][listnodes:$OPTIND]: Option ${OPT} Argument: $OPTARG" >&2
                if [[ -z "$OPTARG" ]] || [[ "$OPTARG" =~ $HELP_OPTION_PATTERN ]]; then
                    print_option_N_usage
                    exit 2
                fi
                read -r -a REGION_ARRAY <<< $(echo ${OPTARG} | tr -d ' ' | tr ',' ' ')
                print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: Region List: ${REGION_ARRAY[@]}"
                listnodes ${REGION_ARRAY[@]}
                ;;
            r | region)
                print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME][region:$OPTIND]: Option ${OPT} Argument: $OPTARG" >&2
                if [[ -z "$OPTARG" ]] || [[ "$OPTARG" =~ $HELP_OPTION_PATTERN ]]; then
                    print_option_r_usage
                    exit 2
                fi
                read -r -a REGION_ARRAY <<< $(echo ${OPTARG} | tr -d ' ' | tr ',' ' ')
                print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: Region List: ${REGION_ARRAY[@]}"
                ;;
            g | geo)
                print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME][geo:$OPTIND]: Option ${OPT} Argument: $OPTARG" >&2
                if [[ -z "$OPTARG" ]] || [[ "$OPTARG" =~ $HELP_OPTION_PATTERN ]]; then
                    print_option_g_usage
                    exit 2
                fi
                read -r -a GEO_ARRAY <<< $(echo ${OPTARG} | tr -d ' ' | tr ',' ' ')
                print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: Geo List: ${GEO_ARRAY[@]}"
                ;;
            n | node)
                print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME][node:$OPTIND]: Option ${OPT} Parameter: ${OPTARG}" >&2
                if [[ -z "$OPTARG" ]] || [[ "$OPTARG" =~ $HELP_OPTION_PATTERN ]]; then
                    print_option_n_usage
                    exit 2
                fi
                read -r -a NODE_ARRAY <<< $(echo ${OPTARG} | tr -d ' ' | tr ',' ' ')
                for node in ${NODE_ARRAY[@]}; do
                    if ! [[ "$node" =~ $VALID_NODE_PATTERN ]]; then
                        print_err_message "[${THIS_UNIQ_ID}][$FUNCNAME]:Node: $node is not in Valid pattern: $VALID_NODE_PATTERN"
                        print_err_message "[${THIS_UNIQ_ID}][$FUNCNAME]:It has to be one or some of the below nodes."
                        listnodes ${REGION_ARRAY[@]}
                    fi
                done
                print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: Nodes List: ${NODE_ARRAY[@]}"
                ;;
            p | plugin)
                print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME][plugin:$OPTIND]: Option ${OPT} Parameter: ${OPTARG}" >&2
                if [[ -z "$OPTARG" ]] || [[ "$OPTARG" =~ $HELP_OPTION_PATTERN ]]; then
                    print_option_p_usage
                    exit 2
                fi
                read -a PLUGIN_ARRAY <<< $(echo ${OPTARG} | tr -d ' ' | tr ',' ' ')
                print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: Plugins List: ${PLUGIN_ARRAY[@]}"
                ;;
            s | script)
                print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME][script:$OPTIND]: Option ${OPT} Parameter: ${OPTARG}" >&2
                if [[ -z "$OPTARG" ]] || [[ "$OPTARG" =~ $HELP_OPTION_PATTERN ]]; then
                    print_option_s_usage
                    exit 2
                fi
                read -a COMMAND_ARRAY <<< $(echo ${OPTARG} | tr -d ' ' | tr ',' ' ')
                print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: Command List: ${COMMAND_ARRAY[@]}"
                ;;
            a | args)
                print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME][args:$OPTIND]: Option ${OPT} Parameter: ${OPTARG}" >&2
                if [[ -z "$OPTARG" ]] || [[ "$OPTARG" =~ $HELP_OPTION_PATTERN ]]; then
                    print_option_a_usage
                    exit 2
                fi
                read -a INPUT_ARGS_ARRAY <<< $(echo ${OPTARG} | tr -d ' ' | tr ',' ' ')
                print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: Command List: ${INPUT_ARGS_ARRAY[@]}"
                ;;
            ??* )
                print_debug_message "Long Option --${OPT} is not a valid option."
                print_usage_short
                ;;
            : )
                parse_short_option_input "${OPTARG}"
                exit 1
                ;;
            ?* )
                print_debug_message "Short Option -${OPTARG} is not a valid option."
                print_usage_short
                ;;

        esac
    done
}

function parse_short_option_input(){
    local this_argument=$1
    print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME] Short Option -${this_argument}"
    case "$this_argument" in
        G)
            listgeos
            ;;
        n|o|N|r|g|p|s)
            print_option_${this_argument}_usage
            ;;
        :)
            print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME] Short Option -${this_argument} requires a value or list of values separated by comma." >&2
            print_option_help_usage ${this_argument}
        ;;
    esac
}

function parse_list_geos_option_input(){
    local this_argument=$1
    print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: Argument: $this_argument"
    if [ -z "$this_argument" ]; then
        listgeos
    else
        read -r -a GEO_ARRAY <<< $(echo ${this_argument} | tr -d ' ' | tr ',' ' ')
        print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: Geo List: ${GEO_ARRAY[@]}"
        listregion_in_geo ${GEO_ARRAY[@]}
    fi
}
function run_diagnostic(){
    if ! [[ ${#GEO_ARRAY[@]} == 0 ]]; then
        REG_CODE=""
        for input_geo in ${GEO_ARRAY[@]}; do
            print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: Initiated diagnostics in Geo: $input_geo"
            readarray -t g_arr < <(jq "keys[]" $REGION_CONFIG_FILE)
            for geo_name in "${g_arr[@]}"; do
                geo_code=$(jq ".$geo_name[0].geography" $REGION_CONFIG_FILE| sed s/\"//g)
                if [[ "$geo_code" == "$input_geo" ]]; then
                    for reg in $(jq ".$geo_name[].name" $REGION_CONFIG_FILE | awk '/oci-native/{printf("%s\n",$0)}' | sed s/\"//g);do
                        _TMP_REG_CODE=$(grep "^Host" ${SSH_CONFIG_FILE[@]} | grep "$reg " | awk '{print $NF}')
                        if ! [[ -z $_TMP_REG_CODE ]]; then
                            REG_CODE=$_TMP_REG_CODE","$REG_CODE
                        fi
                    done
                    print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: GEO Name=$geo_name, GEO CODE=$geo_code, Input GEO=$input_geo, REG_CODE=$REG_CODE"
                fi
            done
        done
        readarray -t REGION_ARRAY < <(echo $REG_CODE | sed s/,$//g | sed s/,/\\n/g)
    fi
    print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]:Region    Array : ${REGION_ARRAY[@]}"
    if ! [[ ${#NODE_ARRAY[@]} == 0 ]]; then
        print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]:Node      Array : ${NODE_ARRAY[@]}"
    fi
    if ! [[ ${#PLUGIN_ARRAY[@]} == 0 ]]; then
        print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]:Plugin    Array : ${PLUGIN_ARRAY[@]}"
    fi
    if ! [[ ${#COMMAND_ARRAY[@]} == 0 ]]; then
        print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]:Command   Array : ${COMMAND_ARRAY[@]}"
    else
        INPUT_ARGS_ARRAY=()
    fi
    if ! [[ ${#INPUT_ARGS_ARRAY[@]} == 0 ]]; then
        print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]:Arguments Array : ${INPUT_ARGS_ARRAY[@]}"
    fi

    if [[ ${#REGION_ARRAY[@]} == 0 ]]; then
        print_err_message "[${THIS_UNIQ_ID}][$FUNCNAME]: No regions provided. We need atleast one region to run diagnostics."
        exit 1
    fi

    if [[ ${#NODE_ARRAY[@]} == 0 ]]; then
        print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: No nodes provided in input. We will go with dynamic list per region"
        DYNAMIC_NODES_LIST=1
    fi
    NO_PLUGINS_TO_RUN=1
    if [[ ${#PLUGIN_ARRAY[@]} == 0 ]]; then
        if [[ ${#COMMAND_ARRAY[@]} == 0 ]]; then
            print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: No plugins/commands provided. Running all plugins"
            get_plugins
        else
            NO_PLUGINS_TO_RUN=0
            print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: Individual script provided at the input."
        fi
    fi
    for region in ${REGION_ARRAY[@]}; do
        print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: Initiated diagnostics in Region: $region"
        if [[ $DYNAMIC_NODES_LIST -eq 1 ]]; then
            print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: No nodes provided. Getting a list of valid nodes from $region"
            get_all_nodes $region
        fi
        if is_region_local $region  ; then
            run_local_region_diagnostics $region
        else
            if transfer_plugins_dir $region; then
                run_remote_region_diagnostics $region
            fi
        fi
    done
    generate_output_data
}

function process_csv_data(){
    local this_output_csv_file=$1
    local this_processed_csv_data
    this_processed_csv_data=$(mktemp)

    print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: Output File Name: $this_output_csv_file, $this_processed_csv_data"
    for this_json_file in $LOG_DIR/$THIS_UNIQ_ID"-command-output-"*".json"; do
        local this_tmp_csv_file=${this_json_file%.json}.csv
        jq -s . $this_json_file | jq '.[] | "\(.region),\(.node),\(.plugin),\(.command),\(.output)"' | sed -e s/^\"//g -e s/\"$//g | tr '@' '\n' | sed s/^\ //g | grep -v ",$" > $this_tmp_csv_file
        NUM_COLUMNS_IN_RESULT=$(( $(head -1 $this_tmp_csv_file | awk -F "," '{printf("%s",NF)}') - 4 ))
        RESULT=$(for index in $(seq 1 $NUM_COLUMNS_IN_RESULT); do printf "RESULT$index,"; done | sed s/,$//g)
        NUMLINES=$(cat $this_tmp_csv_file | wc -l)
        if [[ $NUMLINES -gt 1 ]]; then
            HEADER_INFO=$(head -1 $this_tmp_csv_file | awk -F "," '{printf("%s,%s,%s,%s",$1,$2,$3,$4)}')
            grep -v "^$" $this_tmp_csv_file | awk -v header=$HEADER_INFO '{if ( match($0,header)) {printf("%s\n",$0)} else {printf("%s,%s\n",header,$0)} }' >> $this_processed_csv_data
        else
            cat $this_tmp_csv_file >> $this_processed_csv_data
        fi
        rm -f $this_tmp_csv_file
    done
    echo "RegionName,NodeName,Plugin,Command,$RESULT" > $this_output_csv_file
    cat $this_processed_csv_data >> $this_output_csv_file
}

function generate_output_data(){
    print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: $LOG_DIR/$THIS_UNIQ_ID"-command-output-"*".json""
    if ls $LOG_DIR/${THIS_UNIQ_ID}"-command-output-"*".json" > $DEV_NULL 2>&1; then
        if [[ $OUTPUT_FORMAT_TO_FILE == "json" ]]; then
            jq -s . $LOG_DIR/$THIS_UNIQ_ID"-command-output-"*".json" > $OUTPUT_FILE
        elif [[ $OUTPUT_FORMAT_TO_FILE == "csv" ]]; then
            process_csv_data $OUTPUT_FILE
        elif [[ $OUTPUT_FORMAT_TO_FILE == "html" ]]; then
            TMPCSVFILE=$(mktemp)
            process_csv_data $TMPCSVFILE
            csv2html $TMPCSVFILE > $OUTPUT_FILE
        else
            print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: No format provided. Not generating any output file."
        fi
        rm -f $LOG_DIR/$THIS_UNIQ_ID"-command-output-"*".json"
    else
        print_err_message "[${THIS_UNIQ_ID}][$FUNCNAME]: No output generated [$LOG_DIR/$THIS_UNIQ_ID\"-command-output-\"*\".json\"]"
    fi
}


function run_remote_region_diagnostics(){
    local this_region=$1
    print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]:Region: $this_region"
    for node_group in ${NODE_ARRAY[@]}; do
        print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: Running diagnostics commands on Node Group: $node_group"
        get_nodes $this_region $node_group
        for node in ${NODES_IN_GROUP_ARRAY[@]}; do
            print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: Running diagnostics commands on Node: $node"
            if [[ $NO_PLUGINS_TO_RUN -eq 0 ]]; then
                for script in ${COMMAND_ARRAY[@]}; do
                    print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: Running diagnostics commands[$script] on Node: $node"
                    run_script_remote $region $node $script
                done
            else
                for plugin in ${PLUGIN_ARRAY[@]}; do
                    print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: Running diagnostics Plugin[$plugin] on Node: $node"
                    run_plugin_remote $region $node $plugin
                done
            fi
        done
    done
}

function run_local_region_diagnostics(){
    local this_region=$1
    print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]:Region: $this_region"
    for node_group in ${NODE_ARRAY[@]}; do
        ignore_pattern="api|worker"
        if [[ "$node_group" =~ $ignore_pattern ]]; then
            print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]:Node: $node_group is in Ignore pattern: $ignore_pattern"
            continue
        fi
        print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: Running diagnostics commands on Node: $node_group"
        get_nodes $this_region $node_group
        for node in ${NODES_IN_GROUP_ARRAY[@]}; do
            if [[ $NO_PLUGINS_TO_RUN -eq 0 ]]; then
                for script in ${COMMAND_ARRAY[@]}; do
                    run_script_local $region $node $script
                done
            else
                for plugin in ${PLUGIN_ARRAY[@]}; do
                    run_plugin_local $region $node $plugin
                done
            fi
        done
    done
}

function generate_json_object(){
    local this_input_file_name=$1
    local tmpfile
    tmpfile=$(mktemp)

    print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]:$this_input_file_name, $tmpfile"
    sed -n '/##METADATA-START/,/##METADATA-END/p' $this_input_file_name | grep "^##@" > $tmpfile
    JSON_OBJ_ARGS_LIST=()
    while read -r lines; do
        var_name=$(echo "$lines" | awk -F "##@" '{print $NF}' | awk -F ":" '{print $1}' | sed 's/^ //g' | sed 's/ $//g' | tr '[:upper:]' '[:lower:]')
        var_value=$(echo "$lines" | awk -F "##@" '{print $NF}' | awk -F ":" '{print $NF}' | sed 's/^ //g' | sed 's/ $//g')
        args="--arg $var_name \"$var_value\" "
        JSON_OBJ_ARGS_LIST+=" "$args
    done < $tmpfile
}

function run_plugin_local(){
    local this_region_name=$1
    local this_node_name=$2
    local this_plugin_name=$3

    print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]:[Local]:Region:$this_region_name, Node: $this_node_name, Plugin: $this_plugin_name"
    if [[ -d $PLUGINS_DIR/$this_plugin_name ]]; then
        for command_file in $(ls $PLUGINS_DIR/$this_plugin_name 2> $DEV_NULL); do
            OUTPUT_FILE_NAME=${LOG_DIR}/${THIS_UNIQ_ID}-command-output-${this_node_name}-${this_plugin_name}-${command_file}.json
            print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: Executing Command: $command_file"
            COMMAND_OUTPUT=$(ssh $SSH_OPTIONS $this_node_name 'bash -s' < $PLUGINS_DIR/$this_plugin_name/$command_file |& grep -v "$BANNER_MESSAGE" | grep -v "Last login")
            print_info_message "[${THIS_UNIQ_ID}][$FUNCNAME][$this_region_name] -> [$this_node_name] -> [$this_plugin_name] -> [$command_file] -> [$COMMAND_OUTPUT]"
            if [[ $COMMAND_OUTPUT =~ "Not-Applicable" ]]; then
                print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: This command is not valid on the node"
            else
                generate_json_object $PLUGINS_DIR/$this_plugin_name/$command_file
                tmpfile=$(mktemp)
                echo jq -n --arg region \"$this_region_name\" --arg node \"$this_node_name\" --arg plugin \"$this_plugin_name\" ${JSON_OBJ_ARGS_LIST[@]}  --arg output \"$COMMAND_OUTPUT\" \'''\$ARGS.named\''' > $tmpfile
                bash $tmpfile  > $OUTPUT_FILE_NAME
            fi
        done
    else
        print_err_message "[${THIS_UNIQ_ID}][$FUNCNAME][$this_region_name][$this_node_name]: $this_plugin_name is not a valid Plugin. It must be a folder."
    fi
}

function run_script_local(){
    local this_region_name=$1
    local this_node_name=$2
    local this_script_name=$3
    local this_found_script=1

    print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]:[Local]:Region:$this_region_name, Node: $this_node_name, Script: $this_script_name"
    for plugin_name in $(ls $PLUGINS_DIR); do 
        if [[ -d $PLUGINS_DIR/$plugin_name ]]; then 
            for command_file in $(ls $PLUGINS_DIR/$plugin_name); do
                print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: $PLUGINS_DIR/$plugin_name/$command_file"
                if [ $this_script_name == $command_file ]; then
                    this_found_script=0
                    local this_output_file_name=${LOG_DIR}/${THIS_UNIQ_ID}-command-output-${this_region_name}-${this_node_name}-${plugin_name}-${command_file}.json
                    print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: Executing Command: ${command_file}, Output File: $this_output_file_name"
                    local this_command_output=$(ssh $SSH_OPTIONS $this_node_name 'bash -s' < $PLUGINS_DIR/$plugin_name/$command_file ${INPUT_ARGS_ARRAY[*]} |& grep -v "$BANNER_MESSAGE" | grep -v "Last login")
                    print_info_message "[${THIS_UNIQ_ID}][$FUNCNAME][$this_region_name] -> [$this_node_name]-> [$this_script_name] -> [$this_command_output]"
                    if [[ $this_command_output =~ "Not-Applicable" ]]; then
                        print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: This command is not valid on the node"
                    else
                        generate_json_object $PLUGINS_DIR/$plugin_name/$command_file
                        tmpfile=$(mktemp)
                        echo jq -n --arg region \"$this_region_name\" --arg node \"$this_node_name\" --arg plugin \"$plugin_name\" ${JSON_OBJ_ARGS_LIST[@]}  --arg output \"$this_command_output\" \'''\$ARGS.named\''' > $tmpfile
                        bash $tmpfile  > $this_output_file_name
                    fi
                    break
                fi
            done
        fi
    done
    if [[ $this_found_script -eq 1 ]]; then
        print_err_message "[${THIS_UNIQ_ID}][$FUNCNAME][$this_region_name][$this_node_name]: Script: $this_script_name is not present in $PLUGINS_DIR."
    fi
}

function run_plugin_remote(){
    local this_region_name=$1
    local this_node_name=$2
    local this_plugin_name=$3
    
    print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]:[Remote]:Region:${this_region_name}, Node: ${this_node_name}, Plugin: ${this_plugin_name}"
    for command_file in $(ls $PLUGINS_DIR/${this_plugin_name}); do
        OUTPUT_FILE_NAME=${LOG_DIR}/${THIS_UNIQ_ID}-command-output-${this_node_name}-${this_plugin_name}-${command_file}".json"
        print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: Executing Command: ${command_file}"
        COMMAND="ssh $SSH_OPTIONS ${this_node_name} 'bash -s' < \$HOME/$(basename $PLUGINS_DIR)/${this_plugin_name}/${command_file}"
        print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: SSH Command on Remote: $COMMAND"
        SSH_COMMAND="ssh $SSH_OPTIONS ${this_region_name} export PATH=/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:; $COMMAND"
        print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: SSH Command on Local: $SSH_COMMAND"
        TMPFILE=$(mktemp)
        $SSH_COMMAND > $TMPFILE 2> $DEV_NULL
        STATUS=$?
        if [[ $STATUS -ne 0 ]]; then
            print_err_message "[${THIS_UNIQ_ID}][$FUNCNAME][${this_region_name}][${this_node_name}]: Script: ${command_file} FAILED. Error Code: $STATUS"
            echo "[FAILED]: Error Code: $STATUS." > $TMPFILE
        fi
        COMMAND_OUTPUT=$(cat $TMPFILE | grep -v "$BANNER_MESSAGE" | grep -v "Last login")
        print_info_message "[${THIS_UNIQ_ID}][$FUNCNAME][${this_region_name}] -> [${this_node_name}] -> [${this_plugin_name}] -> [${command_file}] -> [$COMMAND_OUTPUT]"
        rm -f $TMPFILE
        print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: Output: $COMMAND_OUTPUT"
        if [[ $COMMAND_OUTPUT =~ "Not-Applicable" ]]; then
            print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: This command is not valid on the node"
        else
            generate_json_object $PLUGINS_DIR/${this_plugin_name}/${command_file}
            tmpfile=$(mktemp)
            echo jq -n --arg region \"${this_region_name}\" --arg node \"${this_node_name}\" --arg plugin \"${this_plugin_name}\" ${JSON_OBJ_ARGS_LIST[@]}  --arg output \"$COMMAND_OUTPUT\" \'''\$ARGS.named\''' > $tmpfile
            bash $tmpfile  > $OUTPUT_FILE_NAME
        fi
    done    
}

function run_script_remote(){
    local this_region_name=$1
    local this_node_name=$2
    local this_script_name=$3
    local this_found_script=1

    print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]:[Remote]:Region:${this_region_name}, Node: ${this_node_name}, Script: ${this_script_name}"
    for plugin_name in $(ls $PLUGINS_DIR); do 
        if [[ -d $PLUGINS_DIR/${plugin_name} ]]; then 
            for command_file in $(ls $PLUGINS_DIR/${plugin_name}); do
                if [ ${this_script_name} == ${command_file} ]; then
                    this_found_script=0
                    local this_output_file_name=${LOG_DIR}/${THIS_UNIQ_ID}-command-output-${this_region_name}-${this_node_name}-${plugin_name}-${command_file}.json
                    print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: Executing Command: ${command_file}, Output File: $this_output_file_name"
                    local this_remote_ssh_command="ssh $SSH_OPTIONS ${this_node_name} 'bash -s' < \$HOME/$(basename $PLUGINS_DIR)/${plugin_name}/${command_file} ${INPUT_ARGS_ARRAY[*]}"
                    print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: SSH Command on Remote: $this_remote_ssh_command"
                    local this_local_ssh_command="ssh $SSH_OPTIONS ${this_region_name} export PATH=/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:; $this_remote_ssh_command"
                    print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: SSH Command on Local: $this_local_ssh_command"
                    TMPFILE=$(mktemp)
                    $this_local_ssh_command > $TMPFILE 2> $DEV_NULL
                    STATUS=$?
                    if [[ $STATUS -ne 0 ]]; then
                        print_err_message "[${THIS_UNIQ_ID}][$FUNCNAME][${this_region_name}][${this_node_name}]: Script: ${command_file} FAILED. Error Code: $STATUS"
                        echo "[FAILED]: Error Code: $STATUS." > $TMPFILE
                    fi
                    local this_command_output=$(cat $TMPFILE | grep -v "$BANNER_MESSAGE" | grep -v "Last login")
                    print_info_message "[${THIS_UNIQ_ID}][$FUNCNAME][${this_region_name}] -> [${this_node_name}]-> [${this_script_name}] -> [$this_command_output]"
                    print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: Output: $this_command_output"
                    if [[ $this_command_output =~ "Not-Applicable" ]]; then
                        print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: This command is not valid on the node"
                    else
                        generate_json_object $PLUGINS_DIR/${plugin_name}/${command_file}
                        tmpfile=$(mktemp)
                        echo jq -n --arg region \"${this_region_name}\" --arg node \"${this_node_name}\" --arg plugin \"${plugin_name}\" ${JSON_OBJ_ARGS_LIST[@]}  --arg output \"$this_command_output\" \'''\$ARGS.named\''' > $tmpfile
                        bash $tmpfile  > $this_output_file_name
                    fi
                    break
                fi
            done
        fi
    done
    if [[ $this_found_script -eq 1 ]]; then
        print_err_message "[${THIS_UNIQ_ID}][$FUNCNAME][${this_region_name}][${this_node_name}]: Script: ${this_script_name} is not present in $PLUGINS_DIR."
    fi
}


function listgeos(){
    print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]"
    local this_temp_file=$LOG_DIR/$FUNCNAME.json
    rm -f $this_temp_file
    readarray -t g_arr < <(jq "keys[]" $REGION_CONFIG_FILE)
    for geo in "${g_arr[@]}"; do
        geo_code=$(jq ".$geo[0].geography" $REGION_CONFIG_FILE| sed s/\"//g)
        jq -n --arg geography $geo_code --arg regions "$(jq ".$geo[].name" $REGION_CONFIG_FILE | awk '/native/{printf("%s,",$0)} END {printf("\n")}' | sed s/\"//g | sed s/,$//g)" '$ARGS.named' >> $this_temp_file
    done
    jq -s . $this_temp_file
    rm -f $this_temp_file
    exit 0
}

function listregion_in_geo(){
    print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]"
    local geo_list=$@
    local this_temp_file=$LOG_DIR/$FUNCNAME.json
    rm -f $this_temp_file
    print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]:Geo: ${geo_list[@]}"
    readarray -t g_arr < <(jq "keys[]" $REGION_CONFIG_FILE)
    for geo in "${g_arr[@]}"; do
        geo_code=$(jq ".$geo[0].geography" $REGION_CONFIG_FILE| sed s/\"//g)
        if [[ ${geo_list[*]} =~ $geo_code ]]; then
            print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: Found $geo_code"
            jq -n --arg geography $geo_code --arg regions "$(jq ".$geo[].name" $REGION_CONFIG_FILE | awk '/native/{printf("%s,",$0)} END {printf("\n")}' | sed s/\"//g | sed s/,$//g)" '$ARGS.named' >> $this_temp_file
        fi
    done
    if [[ -f $this_temp_file ]]; then
        jq -s . $this_temp_file
        rm -f $this_temp_file
    else
        print_err_message "[${THIS_UNIQ_ID}][$FUNCNAME]: No valid region found in [${geo_list[@]}]"
    fi
    exit 0
}

function listregions(){
	print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: Only Native regions are currently supported."
    local this_temp_file=$LOG_DIR/$FUNCNAME.json
    rm -f $this_temp_file
    for config_file in ${SSH_CONFIG_FILE[@]}; do
        [[ -e "$config_file" ]] || print_err_message_and_exit "[${THIS_UNIQ_ID}][$FUNCNAME]: You dont have any ${SSH_CONFIG_FILE[@]}. This file is needed to list/connect the regions." 
        print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: Processing $config_file"
        if is_region_local $(basename $config_file); then
            region_name="$(basename $config_file)"
            region_type="Local"
        else
            region_name=$(sed -n '/native/p' $config_file | sed 's/Host[\ ]*//g' | awk '{printf("%s, ",$NF)}' | sed 's/, $//g')
            region_type="Remote"
        fi
        jq -n --arg connection_type $region_type --arg ssh_config "$config_file" --arg region "${region_name[@]}" '$ARGS.named' >> $this_temp_file
    done
    jq -s . $this_temp_file
    rm -f $this_temp_file
    exit 0
}

function listnodes(){
    local this_regions_list=$@
    local this_temp_file=$LOG_DIR/$FUNCNAME.json
    rm -f $this_temp_file
    print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]:Region: ${this_regions_list[@]}"
    for region in ${this_regions_list[@]}; do
        get_all_nodes $region
        get_all_groups  $region
        local list_of_nodes
        list_of_nodes=$(echo ${NODE_ARRAY[@]} | sed 's/ /, /g')
        local list_of_node_groups
        list_of_node_groups=$(echo ${NODE_GROUP_ARRAY[@]} | sed 's/ /, /g')

        jq -n --arg region "$region" --arg nodes "$list_of_nodes" --arg groups "$list_of_node_groups" '$ARGS.named' >> $this_temp_file
    done
    jq -s . $this_temp_file
    rm -f $this_temp_file
    exit 0
}

function listplugins(){
    print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: List of available Plugins"
    get_plugins
    jq -n --arg plugins "$(echo "${PLUGIN_ARRAY[@]}"| sed s/^\ //g | sed s/\ /,/g)" '$ARGS.named'
    exit 0
}


function listscripts(){
    print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: List of available Scripts"
    #print_option_s_usage
    get_scripts " "
    exit 0
}

function get_all_groups(){
    NODE_GROUP_ARRAY=()
    local this_region=$1
    local ansible_inventory_file=${WORKING_DIR}/../ansible/inventory/$this_region
    local this_pod_type="Local"

    print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]:Region: $this_region"
    if is_region_local "$this_region"; then
        print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]:[$this_pod_type]: $this_region region can be accessed directly. It doesnt need a bastion so querying the list locally."
        readarray -t THIS_ARRAY < <(ansible-inventory -i "$ansible_inventory_file" --list  | jq -r "keys | .[]" | grep -v "_meta")
    else
        this_pod_type="Remote"
        print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]:[$this_pod_type]: $this_region is a production region"
        readarray -t THIS_ARRAY < <(ssh $SSH_OPTIONS $this_region "ansible-inventory --list | jq -r \"keys | .[]\" | grep -v \"_meta\"" 2> $DEV_NULL)
    fi
    if [[ ${#THIS_ARRAY[@]} == 0 ]]; then
        print_err_message "[${THIS_UNIQ_ID}][$FUNCNAME][$this_region][$this_pod_type]: Getting nodes list failed."
        return 1
    fi
    print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]:Command output from the region($this_region): ${THIS_ARRAY[@]}"
    for node_group in ${THIS_ARRAY[@]}; do        
        NODE_GROUP_ARRAY+=" "$node_group
    done
    print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: Full List of Node Group in $region: ${NODE_GROUP_ARRAY[@]}"
}

function get_all_nodes(){
    NODE_ARRAY=()
    local this_region=$1
    local ansible_inventory_file=${WORKING_DIR}/../ansible/inventory/$this_region
    local this_pod_type="Local"

    print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]:Region: $this_region"
    if is_region_local $this_region; then
        print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]:[$this_pod_type]: $this_region region can be accessed directly. It doesnt need a bastion so querying the list locally."
        readarray -t THIS_ARRAY < <(ansible -i $ansible_inventory_file all --list-hosts | grep -v hosts | grep ${this_region%-*})
    else
        this_pod_type="Remote"
        print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]:[$this_pod_type]: $this_region is a production region"
        readarray -t THIS_ARRAY < <(ssh $SSH_OPTIONS $this_region "ansible all --list-hosts | grep -v hosts" 2> $DEV_NULL)
    fi
    if [[ ${#THIS_ARRAY[@]} == 0 ]]; then
        print_err_message "[${THIS_UNIQ_ID}][$FUNCNAME][$this_region][$this_pod_type]: Getting nodes list failed."
        return 1
    fi
    print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]:Command output from the region($this_region): ${THIS_ARRAY[@]}"
    for node in ${THIS_ARRAY[@]}; do
        NODE_ARRAY+=" "$node
    done
    print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: Full List of Nodes in $region: ${NODE_ARRAY[@]}"
}

function get_nodes(){
    NODES_IN_GROUP_ARRAY=()
    local this_region=$1
    local this_node_group=$2
    local this_ansible_inventory_file=${WORKING_DIR}/../ansible/inventory/${this_region}
    local this_pod_type="Local"
    print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]:Region: ${this_region}, $this_ansible_inventory_file"
    if is_region_local ${this_region}; then
        print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]:[$this_pod_type]: ${this_region} region can be accessed directly. It doesnt need a bastion so querying the list locally."
        readarray -t THIS_ARRAY < <(ansible -i $this_ansible_inventory_file ${this_node_group} --list-hosts | grep -v hosts | grep ${this_region%-*})
    else
        this_pod_type="Remote"
        print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]:[$this_pod_type]: ${this_region} is a production region"
        # shellcheck disable=SC2029
        readarray -t THIS_ARRAY < <(ssh $SSH_OPTIONS ${this_region} "ansible ${this_node_group} --list-hosts | grep -v hosts" 2> $DEV_NULL)
    fi
    if [[ ${#THIS_ARRAY[@]} == 0 ]]; then
        print_err_message "[${THIS_UNIQ_ID}][$FUNCNAME][${this_region}][$this_pod_type]: Getting nodes list failed."
        return 1
    fi
    print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]:Command output from the region(${this_region}): ${THIS_ARRAY[@]}"
    for node in ${THIS_ARRAY[@]}; do
        NODES_IN_GROUP_ARRAY+=" "$node
    done
    print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: Full List of Nodes in $region: ${NODES_IN_GROUP_ARRAY[@]}"
}


function get_plugins(){
    print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: Plugins location: $PLUGINS_DIR"
    for fldrs in $(ls $PLUGINS_DIR); do 
        if [[ -d $PLUGINS_DIR/$fldrs ]]; then 
            PLUGIN_ARRAY+=" "$fldrs
            print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: Plugins: ${PLUGIN_ARRAY[@]}"
        else
            print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: Not a folder: $PLUGINS_DIR/$fldrs"
        fi
    done
    print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: List of plugins: ${PLUGIN_ARRAY[@]}"
}

function get_scripts(){
    local this_count=0
    local this_spacing=$1

    for plugin_name in $(ls $PLUGINS_DIR); do 
        if [[ -d $PLUGINS_DIR/$plugin_name ]]; then 
            SCRIPT_INFO=""
            for command_file in $(ls $PLUGINS_DIR/$plugin_name); do
                print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: $PLUGINS_DIR/$plugin_name/$command_file"
                header_data=$(parse_script_header $PLUGINS_DIR/$plugin_name/$command_file)
                name=$(echo "$header_data" | awk -F ":" '/^\"command\"/ {print $NF}' | sed 's/\"//g')
                desc=$(echo "$header_data" | awk -F ":" '/^\"description\"/ {print $NF}' | sed 's/\"//g')
                #echo -e "${this_spacing}${this_spacing}$this_count. $name:$desc"
                this_count=$((this_count+1))
                SCRIPT_INFO=$SCRIPT_INFO"${this_spacing}${this_spacing}${this_spacing}${this_count}. $name:$desc\n"
            done
            echo -e "${this_spacing}[$plugin_name]: Number of Scripts=${this_count}"
            echo -e "$SCRIPT_INFO"
            this_count=0
        fi
    done
}

function parse_script_header(){
    local this_input_file_name=$1
    local tmpfile
    tmpfile=$(mktemp)

    print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]:$this_input_file_name, $tmpfile"
    sed -n '/##METADATA-START/,/##METADATA-END/p' $this_input_file_name | grep "^##@" > $tmpfile
    while read -r lines; do
        var_name=$(echo "$lines" | awk -F "##@" '{print $NF}' | awk -F ":" '{print $1}' | sed 's/^ //g' | sed 's/ $//g' | tr '[:upper:]' '[:lower:]')
        var_value=$(echo "$lines" | awk -F "##@" '{print $NF}' | awk -F ":" '{print $NF}' | sed 's/^ //g' | sed 's/ $//g')
        echo "\"$var_name\":\"$var_value\""
    done < $tmpfile
}

function enable_debug(){
    VERBOSE_LOGGING=true
    print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME][$VERBOSE_LOGGING]"
}

function enable_json_output(){
    print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]"
    OUTPUT_FORMAT_TO_FILE=json
}

function enable_csv_output(){
    print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]"
    OUTPUT_FORMAT_TO_FILE=csv
}

function enable_html_output(){
    print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]"
    OUTPUT_FORMAT_TO_FILE=html
}


function show_version(){
    echo "$SCRIPTNAME version: v1.00"
    exit 0
}

function is_region_local(){
    this_region=$1
    print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: $this_region"
    if [[ $this_region =~ $LOCAL_POD_PATTERN ]]; then
        print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: $this_region region can be accessed directly."
        return 0
    else
        print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: $this_region needs a bastion"
        return 1
    fi
}

function transfer_plugins_dir(){
    region_name=$1
    print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]:[Remote]:Region:$region_name"
    SCP_COMMAND="rsync -rhq --delete -e ssh $PLUGINS_DIR $region_name:."
    print_debug_message "[${THIS_UNIQ_ID}][$FUNCNAME]: Copying the plugins: $SCP_COMMAND"
    $SCP_COMMAND > $DEV_NULL 2>&1
    STATUS=$?
    if [[ $STATUS -ne 0 ]]; then
        print_err_message "[${THIS_UNIQ_ID}][$FUNCNAME][$region_name]: Transferring plugins FAILED. Error Code: $STATUS"
    fi
    return $STATUS
}

function main(){
    if [[ $# -eq 0 ]]; then
        print_usage
    fi
    initialise
    parse_inputs "$@"
    print_debug_message "[$@]:Started : $(date)"
    run_diagnostic
    print_debug_message "[$@]:Finished : $(date)"
    exit 0
}

#------------------------------------------------------------
# Main program execution start here.
#------------------------------------------------------------
THIS_UNIQ_ID=$$
FULL_PATH=$(realpath $0)
SCRIPTNAME=$(basename ${FULL_PATH})
WORKING_DIR=$(dirname $(dirname $(dirname ${FULL_PATH})))
SCRIPTS_DIR=${WORKING_DIR}/scripts
LIB_DIR=${SCRIPTS_DIR}/lib
PLUGINS_DIR=${WORKING_DIR}/plugins
VERBOSE_LOGGING=false
OUTPUT_FORMAT_TO_FILE=console

REGION_CONFIG_FILE=$WORKING_DIR/config/regions.json
LOG_DIR=${WORKING_DIR}/logs
DATE_TIMESTAMP=$(date "+%d%m%Y")
LOGFILE=${LOG_DIR}/${SCRIPTNAME}_${DATE_TIMESTAMP}_${THIS_UNIQ_ID}.log
mkdir -p $LOG_DIR

OUTPUT_FILE=/dev/stdout
DEV_NULL=/dev/null

source $LIB_DIR/logger.sh
source $LIB_DIR/html_generator.sh
source $LIB_DIR/usage_help_functions.sh
source $LIB_DIR/common_utils_functions.sh

trap script_exit EXIT
trap script_interrupt SIGINT

exec > >(tee -i $LOGFILE) 2>&1
main "$@"
