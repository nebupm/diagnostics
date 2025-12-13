##METADATA-START
##@Command : getactiveconncount.sh
##@Description: Queries the current number of active connections/sessions.
##@Help : This can be used to check if the DB's are taking connection after bouncing the node.
##@Category :Status Check
##METADATA-END

this_node=$(uname -n)
pattern="devcsdb|vbstudio-db"
if [[ "$this_node" =~ $pattern ]]; then
    cat > /tmp/getactiveconncount.sql <<EOF
SET PAGESIZE 0
SET LINESIZE 80
select inst_id, count(*) from gv\$session group by inst_id;
quit
EOF
    sudo su - oracle <<EOF
\$ORACLE_HOME/bin/sqlplus -S / as sysdba @/tmp/getactiveconncount.sql | grep -v "^\$" > /tmp/getactiveconncount.log
EOF
    awk '{printf("DB%s[%s],",$1,$NF)}' /tmp/getactiveconncount.log | sed s/,$//g
    rm /tmp/getactiveconncount.sql
else
    echo "Not-Applicable"
fi
exit 0
