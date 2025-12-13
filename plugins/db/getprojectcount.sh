##METADATA-START
##@Command : getprojectcount.sh
##@Description: Queries the current number of projects and the max allowed setings from the db node.
##@Help : Always ensure that #Projects < Max Projects config.
##@Category :Config Check
##METADATA-END

this_node=$(uname -n)
pattern="devcsdb|vbstudio-db"
if [[ "$this_node" =~ $pattern ]]; then
    cat > /tmp/getprojectcount.sql <<EOF
SET PAGESIZE 0
SET LINESIZE 80
alter session set container=pdb;
alter session set current_schema=profile;
select value from configurationproperty where name='system.project.maxnum';
select count(*) from project;
quit
EOF
    sudo su - oracle <<EOF
\$ORACLE_HOME/bin/sqlplus -S / as sysdba @/tmp/getprojectcount.sql | grep -v "Session altered" | grep -v "^\$" > /tmp/getprojectcount.log
EOF
echo "#Projects=$(tail -1 /tmp/getprojectcount.log | awk '{print $NF}'), Max Projects config=$(head -1 /tmp/getprojectcount.log)"
else
    echo "Not-Applicable"
fi
exit 0
