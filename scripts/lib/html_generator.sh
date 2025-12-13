#! /usr/bin/env bash

# shellcheck disable=SC2155
# shellcheck disable=SC2086
# shellcheck disable=SC2128

function print_css(){
    cat << EOF
<style type="text/css" media="screen">
    table {
        vertical-align: top;
        border: 3px solid #000000;
        width: 100%;
        text-align: center;
        border-collapse: collapse;
        border-radius:6px;
    }
    td {
        text-align: left;
        vertical-align: center;
        border: 1px solid #000000;
        padding: 5px 4px;
        font-size: 13px;
        min-width: 140px
    }
    th {
        text-align: center;
        vertical-align: center;
        border: 1px solid #000000;
        height: 50px;
        padding: 5px 4px;
        font-size: 13px;
        font-size: 15px;
        font-weight: bold;
        background-color: #04AA6D;
        color: white;
    }
    tr:hover {background-color: coral;}
    tbody{
        font-size: 13px;
    }
    thead {
        background: #CFCFCF;
        background: -moz-linear-gradient(top, #dbdbdb 0%, #d3d3d3 66%, #CFCFCF 100%);
        background: -webkit-linear-gradient(top, #dbdbdb 0%, #d3d3d3 66%, #CFCFCF 100%);
        background: linear-gradient(to bottom, #dbdbdb 0%, #d3d3d3 66%, #CFCFCF 100%);
        border-bottom: 3px solid #000000;
        font-size: 15px;
        font-weight: bold;
        color: #000000;
    }
</style>
EOF
}

print_header(){
    local input_data_file=$1
    if [[ -f $input_data_file ]]; then
        cat $input_data_file
    fi
}

print_footer(){
    local input_data_file=$1
    if [[ -f $input_data_file ]]; then
        cat $input_data_file
    fi
}

print_table_data(){
    local input_csv_file=$1
    if ! [[ -f $input_csv_file ]]; then
        echo "$input_csv_file not found. Exiting"
        return 1
    fi

    local header_line=true
    local delimiter=","
    echo "<div style=\"overflow-x: auto;\">"
    echo "<table>"
    local number_of_columns=$(head -1 $input_csv_file | awk -F $delimiter '{print NF}')
    while read -r line; do
        count=1
        if $header_line ; then
            echo "<thead>"
            echo "<tr>"
            for index in $(seq $count $number_of_columns); do
                if [[ $index -eq 1 ]]; then
                    BOLD_OPEN="<strong>"
                    BOLD_CLOSE="</strong>"
                else
                    BOLD_OPEN=""
                    BOLD_CLOSE=""
                fi
                #VALUE=$(echo $line | awk -F $delimiter -v i=$index '{print $i}' | sed s/\ /\&nbps\;/g)
                VALUE=$(echo $line | awk -F $delimiter -v i=$index '{print $i}')
                echo "<th>${BOLD_OPEN}$VALUE${BOLD_CLOSE}</th>"
            done
            echo "</tr>"
            echo "</thead>"
            echo "<tbody>"
            header_line=false
            continue
        fi
        echo "<tr>"
        for index in $(seq $count $number_of_columns); do 
            if [[ $index -eq 1 ]]; then
                BOLD_OPEN="<strong>"
                BOLD_CLOSE="</strong>"
            else
                BOLD_OPEN=""
                BOLD_CLOSE=""
            fi
            #VALUE=$(echo $line | awk -F $delimiter -v i=$index '{print $i}' | sed s/\ //g)
            VALUE=$(echo $line | awk -F $delimiter -v i=$index '{print $i}')
            echo "<td>${BOLD_OPEN}$VALUE${BOLD_CLOSE}</td>"
        done
        echo "</tr>"
    done < $input_csv_file
    echo "</tbody>"
    echo "</table>"
    echo "</div>"
    return 0
}

function write_html_header(){
    TITLE=$1
    shift
    HEADER4=$1
    shift
    BODY=$@
    if [[ -z $BODY ]]; then
        RESTOFTHEMESSAGE="<p></p>"
    else
        RESTOFTHEMESSAGE="<p>$BODY</p>"

    fi
    cat << EOF
<html>
<hr />
<h3 class="aligncenter"><strong>## Automated Email ##</strong></h3>
<hr />
<p>
<strong style="color: #000;">$TITLE </strong>
<br /><br />
Dated : $(date)
<br />
<h4>$HEADER4</h4>
$RESTOFTHEMESSAGE
EOF
}

function write_html_footer(){
    BODY=$@
    if [[ -z $BODY ]]; then
        RESTOFTHEMESSAGE="<p></p>"
    else
        RESTOFTHEMESSAGE="<p>$BODY</p>"

    fi
    cat << EOF
<br />
$RESTOFTHEMESSAGE
<br />
</html>
EOF
}

function csv2html(){
    print_css
    print_header "$2"
    if ! print_table_data "$1" ; then
        return 1
    fi
    print_footer "$3"
    return 0
}

function send_email(){
    EMAILID=$1
    SUBJECT=$2
    MAILBODY_FILE=$3
    # shellcheck disable=SC2034
    ATTACHMENT_FILE=$4
    CONTENTTYPE="set content_type=text/html"
    
    if mutt -e "$CONTENTTYPE" -s "$SUBJECT" -a "$ATTACHMENT_FILE" -- "$EMAILID" < "$MAILBODY_FILE"; then
        echo "[$FUNCNAME] Email sent to $EMAILID with subject: $SUBJECTLINE"
        return 0
    fi
    echo "[$FUNCNAME] Failed to send email to $EMAILID"
    return 1
}

function render_email_message(){
    local input_file_name=$1
    shift
    local email_subject=$1
    shift
    local email_body_html_header_msg1=$1
    shift
    local email_body_html_header_msg2=$1
    shift
    local email_body_html_footer_msg=$*
    local html_header_file=$(mktemp).html
    local html_footer_file=$(mktemp).html
    local temp_html_file=${RESULT_CSV_FILE%.csv}.html
    if [[ $(grep -c "" $input_file_name) -eq 0 ]]; then
        echo "Empty csv files : $input_file_name"
        echo "HTML Results Not generated"
        return 1
    fi
    
    head -1 "$input_file_name" > "$RESULT_CSV_FILE"
    grep -v "NodeName" "$input_file_name" | sort --reverse -n -t "," -k 2 >> "$RESULT_CSV_FILE"
    write_html_header "$email_body_html_header_msg1" "$email_body_html_header_msg2" > "$html_header_file"
    write_html_footer "$email_body_html_footer_msg" > "$html_footer_file"
    if ! csv2html "$RESULT_CSV_FILE" "$html_header_file" "$html_footer_file" > "$temp_html_file"; then
        echo "[$FUNCNAME] Something not right with $RESULT_CSV_FILE"
        return 1
    fi
    if [[ -n $EMAILIDS ]]; then
        send_email "$EMAILIDS" "$email_subject" "$temp_html_file" "$RESULT_CSV_FILE"
    fi
    echo "CSV Results generated in $RESULT_CSV_FILE"
    echo "HTML Results generated in $temp_html_file"
    return 0
}
