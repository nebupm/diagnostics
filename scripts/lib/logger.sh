#! /usr/bin/env bash

function print_info_message(){
    echo -e "$(date "+[%Y-%m-%d %H:%M:%S]")[INFO][$SCRIPTNAME]: ${@}"
}

function print_err_message(){
    echo -e "$(date "+[%Y-%m-%d %H:%M:%S]")[ERROR][$SCRIPTNAME]: ${@}"
}

function print_err_message_and_exit(){
    echo -e "$(date "+[%Y-%m-%d %H:%M:%S]")[ERROR][$SCRIPTNAME]: ${@}"
    exit 1
}


function print_warn_message(){
    echo -e "$(date "+[%Y-%m-%d %H:%M:%S]")[WARN][$SCRIPTNAME]: ${@}"
}

function print_debug_message(){
    $VERBOSE_LOGGING && echo -e "$(date "+[%Y-%m-%d %H:%M:%S]")[DEBUG][$SCRIPTNAME]: ${@}"
}

function print_file_contents(){
    _filename=$1
    if [[ -f $_filename ]]; then
        echo -e "$(date "+[%Y-%m-%d %H:%M:%S]")[DEBUG][$SCRIPTNAME]: $_filename\n$(cat $_filename)"
    fi
}

function script_interrupt(){
    print_info_message "[$FUNCNAME] : User Entered CTRL-C"
    if [[ ${VERBOSE_LOGGING} -eq 1 ]]; then
        set +x
    fi
    exit 1
}

function script_exit(){
    echo ""
    if [[ ${VERBOSE_LOGGING} -eq 1 ]]; then
        set +x
    fi
}
