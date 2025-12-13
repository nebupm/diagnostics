#! /usr/bin/env bash

function print_usage_no_options(){
    echo -e "\nOptions without Arguments "
    echo " -G|--listgeos List all geo"
    echo " -R|--listregions List all regions"
    echo " -P|--listplugins List all plugins"
    echo " -S|--listscripts List all scripts"
    echo " -h|--help Show this help"
    echo " -d|--debug Enable debug mode with verbose logging"
    echo " -j|--json Print output in json. Default: Console output"
    echo " -c|--csv Print output in csv. Default: Console output"
    echo " -v|--version Show the version"
}

function print_usage_options(){
    echo -e "\nOptions with Arguments "
    echo " -g <Geo or Geos separated by ,> or --geo=<Geo or Geos separated by ,>"
    echo " -r <Region or Regions separated by ,> or --region=<Region or Regions separated by ,>"
    echo " -p <Plugin or Plugins separated by ,> or --plugin=<Plugin or Plugins separated by ,>"
    echo " -n <Node or Nodes separated by ,> or --node=<Node or Nodes separated by ,>"
    echo " -s <Script or Scripts separated by ,> or --script=<Script or Scripts separated by ,>"
    echo " -a <Arguments to script separated by ,> or  --args=<Arguments to script separated by ,>"
    echo " -N <Region or Regions separated by ','. Example: lhr,mel,syd> or--listnodes=<Region or Regions separated by ','. Example: lhr,mel,syd>"
    echo " -o <Name of the file to dump the results> or --output=<Name of the file to dump the results>"
}
function print_usage_short(){
    echo "Usage: $SCRIPTNAME -h / --help for help"
    echo "Usage: $SCRIPTNAME [Options] [Arguments]"
    print_usage_options
    print_usage_no_options
    exit 1
}

function print_usage(){
    echo "Usage: $SCRIPTNAME -h / --help for help"
    echo "Usage: $SCRIPTNAME [Options] [Arguments]"
    echo "Options with Arguments "
    print_option_g_usage
    print_option_r_usage
    print_option_p_usage
    print_option_n_usage
    print_option_s_usage
    print_option_a_usage
    print_option_N_usage
    print_option_o_usage
    print_usage_no_options
    exit 1
}

function print_option_help_usage(){
    print_debug_message "[$FUNCNAME]: Option: -$1"
    if [[ -z $1 ]]; then
        print_debug_message "[$FUNCNAME]: Option -$1 is not valid"
    else
        print_option_${1}_usage
    fi
}

function print_option_g_usage(){
    print_debug_message "[$FUNCNAME]"
    echo " -g <Geo or Geos separated by ,>"
    echo " --geo=<Geo or Geos separated by ,>"
    echo -e "\tRun diagnostics on a Geo. This will supercede region option if both geo and region is give in the input"
    echo -e "\tExample:"
    echo -e "\t\t$SCRIPTNAME -g emea or $SCRIPTNAME --geo=emea Run diagnostics on all the regions in this geo."
    echo -e "\t\t$SCRIPTNAME -g emea,lad or $SCRIPTNAME --geo=emea,lad Run diagnostics on all the regions in this geo."
    echo ""    
}

function print_option_r_usage(){
    print_debug_message "[$FUNCNAME]"
    echo " -r <Region or Regions separated by ,>"
    echo " --region=<Region or Regions separated by ,>"
    echo -e "\tRun diagnostics on a region. This is a mandatory argument for running diagnostics."
    echo -e "\tExample:"
    echo -e "\t\t$SCRIPTNAME -r lhr or $SCRIPTNAME --region=lhr Run diagnostics on all the nodes specified."
    echo -e "\t\t$SCRIPTNAME -r lhr,phx or $SCRIPTNAME --region=lhr,phx Run diagnostics on all the nodes specified."
    echo ""
}

function print_option_n_usage(){
    print_debug_message "[$FUNCNAME]"
    echo " -n <Node or Nodes separated by ,>"
    echo " --node=<Node or Nodes separated by ,>"
    echo -e "\tRun diagnostics on a node or list of nodes. This is not a mandatory argument."
    echo -e "\tThis can also be a node group for example hub or dataplane or controlplane."
    echo -e "\tThe name is exactly the same as ansible inventory."
    echo -e "\tExample:"
    echo -e "\t\t$SCRIPTNAME -r lhr -n hub1,hub2 OR $SCRIPTNAME --region=lhr --node=hub1,hub2 Run diagnostics in the given region and the given nodes."
    echo -e "\t\t$SCRIPTNAME -r lhr -n hub OR $SCRIPTNAME --region=lhr --node=hub Run diagnostics in the given region and the given node group."
    echo -e "\t\t$SCRIPTNAME --region=lhr If -n or --node option is not given, then all the nodes in the region are considered for diagnosis."
    echo ""
}

function print_option_p_usage(){
    print_debug_message "[$FUNCNAME]"
    echo " -p <Plugin or Plugins separated by ,>"
    echo " --plugin=<Plugin or Plugins separated by ,>"
    echo -e "\tA plugin is a collection of similar commands grouped according to their function."
    echo -e "\tExample:"
    echo -e "\t\t$SCRIPTNAME -r lhr -n hub1 -p devcs,disk OR $SCRIPTNAME --region=lhr --node=hub1 --plugin=devcs,disk Run the both plugins"
    echo -e "\t\t$SCRIPTNAME --region=lhr --node=hub1  If -p or --plugin option is not given, then all the plugins are considered in the diagnosis."
    echo -e "\t\t$SCRIPTNAME --region=lhr If --plugin or --node option is not given, then all the plugins will be run on all the nodes in the region."
}

function print_option_s_usage(){
    print_debug_message "[$FUNCNAME]"
    echo " -s <Script or Scripts separated by ,>"
    echo " --script=<Script or Scripts separated by ,>"
    echo -e "\tYou can run individual script in a plugin as well."
    echo -e "\tExample:"
    echo -e "\t\t$SCRIPTNAME -r lhr -n hub1 -s devcs_ver.sh  OR $SCRIPTNAME -r lhr -n hub1 --script=devcs_ver.sh Run the script devcs_ver.sh on hub1 in lhr"
    echo -e "\t\t$SCRIPTNAME -r lhr -n hub1 -s devcs_ver.sh,tomcat_ver.sh  OR $SCRIPTNAME -r lhr -n hub1 --script=devcs_ver.sh,tomcat_ver.sh Run both the scripts"
    #echo -e "\n\tList of commands in each plugins and explanation of available commands."
    #get_scripts "\t "
    echo ""
}

function print_option_a_usage(){
    print_debug_message "[$FUNCNAME]"
    echo " -a <Arguments to script separated by ,>"
    echo " --args=<Arguments to script separated by ,>"
    echo -e "\tYou can pass argument to individual script."
    echo -e "\tExample:"
    echo -e "\t\t$SCRIPTNAME --region=oci-native-ashburn --node=hub1 --script=list_vbs_proj.sh --args=exvu-test-ttjb5b-mpaasvbshsmpp-iad Run the script list_vbs_proj.sh on hub1 in ashburn with argument as the org id."
}

function print_option_o_usage(){
    print_debug_message "[$FUNCNAME]"
    echo " -o <Name of the file to dump the results>"
    echo " --output=<Name of the file to dump the results>"
}

function print_option_N_usage(){
    echo " -N <Region or Regions separated by ','. Example: lhr,mel,syd>"
    echo " --listnodes=<Region or Regions separated by ','. Example: lhr,mel,syd>"
    echo -e "\tThis command will list all the servers in a region. It will also list the node groups for example controlplane, dataplane etc."
    echo -e "\tUser can give multiple regions to the command"
    echo -e "\tExample:"
    echo -e "\t\t$SCRIPTNAME -N lhr this option will list all the nodes/servers in the lhr region"
    echo -e "\t\t$SCRIPTNAME -N lhr,hyd this option will list all the nodes/servers in the lhr and hyd region"
    echo -e "\t\t$SCRIPTNAME --listnodes=lhr this option will list all the nodes/servers in the lhr region."
    echo -e "\t\t$SCRIPTNAME --listnodes=lhr,hyd this option will list all the nodes/servers in the lhr and hyd region"
    echo ""
}
