# Infrastructure Diagnostics Framework

A comprehensive bash-based diagnostics automation framework for running health checks, gathering metrics, and monitoring infrastructure across multiple regions and node groups. This framework supports both local and remote execution via SSH with flexible output formats.

## Overview

The Infrastructure Diagnostics Framework provides a plugin-based architecture for executing diagnostic scripts across distributed infrastructure environments. It leverages Ansible for dynamic node discovery and supports execution through bastion hosts for remote regions.

## Features

- **Multi-region execution** - Run diagnostics across multiple geographic regions simultaneously
- **Plugin-based architecture** - Organize related diagnostic scripts into logical groups
- **Flexible targeting** - Execute on specific nodes, node groups, or entire regions
- **Multiple output formats** - JSON, CSV, and HTML with email integration
- **Remote execution** - Automated plugin transfer and execution through bastion hosts
- **Dynamic discovery** - Automatic node detection using Ansible inventory
- **Comprehensive logging** - Timestamped logs with debug mode support

## Requirements

### System Requirements
- **Bash**: Version 5.0 or higher
- **Operating System**: Linux (tested on RHEL/CentOS)

### Dependencies
- `jq` - JSON processing and parsing
- `ansible` - Infrastructure inventory and node management
- `ssh` - Remote command execution
- `rsync` - Plugin file synchronization
- `mutt` - Email notifications (optional, for wrapper scripts)

## Directory Structure

```
infrastructure-diagnostics/
├── scripts/
│   ├── bin/
│   │   └── run_diagnostics.sh          # Main diagnostics engine
│   ├── utils/                           # Specialized wrapper scripts
│   │   ├── get_cert_dates_region.sh    # Certificate validity checker
│   │   ├── db_lock_diag_region.sh      # Database lock file detector
│   │   ├── docker_fs_size_region.sh    # Docker filesystem monitor
│   │   └── jvmlog_stats_region.sh      # JVM log statistics
│   └── lib/
│       ├── logger.sh                    # Logging functions
│       ├── html_generator.sh            # HTML/email report generator
│       ├── usage_help_functions.sh      # Help and usage text
│       └── common_utils_functions.sh    # Shared utility functions
├── plugins/                             # Diagnostic plugin directories
│   ├── database/                        # Database-related checks
│   │   ├── getactiveconncount.sh
│   │   └── getprojectcount.sh
│   ├── system/                          # System-level diagnostics
│   │   ├── high_disk_usage.sh
│   │   ├── filesystem_usage.sh
│   │   └── backup_status.sh
│   └── application/                     # Application checks
│       └── tomcat_log.sh
├── config/
│   └── regions.json                     # Region configuration
├── ansible/
│   └── inventory/                       # Ansible inventory files per region
└── logs/                                # Execution logs and results
```

## Configuration

### Region Configuration (`config/regions.json`)

Defines geographic regions and their properties:

```json
{
  "North America": [
    {
      "realm": "commercial",
      "name": "hollywood",
      "identifier": "Hollywood Studios",
      "geography": "na",
      "key": "holly"
    }
  ],
  "EMEA": [
    {
      "realm": "commercial",
      "name": "westminister",
      "identifier": "Westminster",
      "geography": "emea",
      "key": "lon"
    }
  ]
}
```

### Environment Variables

Key variables defined in `common_utils_functions.sh`:

```bash
LOCAL_POD_PATTERN="oci-native-alm|earth|alm|lunar|solar|developer-us"
SSH_CONFIG_FILE=(~/.ssh/earth ~/.ssh/lunar ~/.ssh/solar)
SSH_OPTIONS="-o StrictHostKeyChecking=no -o ConnectTimeout=30 -q"
BANNER_MESSAGE="Use of the Oracle network..."
```

### Ansible Inventory

- **Location**: `ansible/inventory/[region_name]`
- **Format**: Standard Ansible inventory (INI or YAML)
- **Purpose**: Defines node groups (controlplane, dataplane, web, database, etc.)

## Usage

### Main Diagnostics Script

```bash
scripts/bin/run_diagnostics.sh [OPTIONS]
```

### Command-Line Options

#### Options with Arguments

| Short | Long | Description |
|-------|------|-------------|
| `-g` | `--geo` | Geography code (na, emea, apac) - comma-separated |
| `-r` | `--region` | Region name(s) - comma-separated |
| `-n` | `--node` | Node name(s) or node group(s) - comma-separated |
| `-p` | `--plugin` | Plugin name(s) - comma-separated |
| `-s` | `--script` | Individual script name(s) - comma-separated |
| `-a` | `--args` | Arguments to pass to scripts - comma-separated |
| `-o` | `--output` | Output file path |
| `-N` | `--listnodes` | List nodes in specified region(s) |

#### Options without Arguments

| Short | Long | Description |
|-------|------|-------------|
| `-R` | `--listregions` | List all configured regions |
| `-G` | `--listgeos` | List all geographies |
| `-P` | `--listplugins` | List available plugins |
| `-S` | `--listscripts` | List all scripts with descriptions |
| `-j` | `--json` | Output in JSON format |
| `-c` | `--csv` | Output in CSV format |
| `-x` | `--html` | Output in HTML format |
| `-d` | `--debug` | Enable debug logging |
| `-v` | `--version` | Show version |
| `-h` | `--help` | Show help message |

### Examples

#### Discovery Commands

```bash
# List all regions
./run_diagnostics.sh -R

# List all geographies
./run_diagnostics.sh -G

# List regions in specific geographies
./run_diagnostics.sh -G na,emea

# List nodes in a region
./run_diagnostics.sh -N hollywood

# List all plugins
./run_diagnostics.sh -P

# List all scripts with descriptions
./run_diagnostics.sh -S
```

#### Running Diagnostics

```bash
# Run all plugins on all nodes in a region
./run_diagnostics.sh -r hollywood

# Run specific plugin
./run_diagnostics.sh -r hollywood -p system

# Run on specific node groups
./run_diagnostics.sh -r hollywood -n controlplane,dataplane -p database

# Run specific script with arguments
./run_diagnostics.sh -r hollywood -n web -s filesystem_usage.sh -a "/var/log"

# Run across multiple regions
./run_diagnostics.sh -r hollywood,westminister -p system

# Run by geography
./run_diagnostics.sh -g na -p application
```

#### Output Format Examples

```bash
# JSON output
./run_diagnostics.sh -r hollywood -p system -j -o results.json

# CSV output
./run_diagnostics.sh -r hollywood -p system -c -o results.csv

# HTML output
./run_diagnostics.sh -r hollywood -p system -x -o results.html

# Console output with debug
./run_diagnostics.sh -r hollywood -p system -d
```

## Plugin Development

### Plugin Structure

Plugins are directories containing related diagnostic scripts:

```
plugins/
└── system/
    ├── high_disk_usage.sh
    ├── filesystem_usage.sh
    └── backup_status.sh
```

### Script Metadata Format

Each script must include metadata headers:

```bash
#!/usr/bin/env bash

##METADATA-START
##@Command: script_name.sh
##@Description: Brief description of what the script does
##@Help: Detailed usage information
##@Category: Stats|Config Check|Status Check
##METADATA-END

# Script implementation
# ...
```

### Script Implementation Guidelines

1. **Return "Not-Applicable"** if the check doesn't apply to the node
2. **Output format**: Comma-separated values for CSV parsing
3. **Use sudo** for privileged operations
4. **Handle errors** gracefully with meaningful messages
5. **Keep scripts focused** on a single diagnostic task

### Example Plugin Script

```bash
##METADATA-START
##@Command: filesystem_usage.sh
##@Description: Shows filesystem usage for specified mount point
##@Help: Pass mount point as argument, defaults to root
##@Category: Stats
##METADATA-END

this_node=$(uname -n)
pattern="dp-node|cp-node"
filesystem_name=$@

if [[ -z $filesystem_name ]]; then
    filesystem_name="root"
fi

if [[ "$this_node" =~ $pattern ]]; then
    result=$(sudo df -h | grep $filesystem_name)
    if [[ $? -ne 0 ]]; then
        echo "$this_node,$filesystem_name,NA,NA,NA"
    else
        echo $result | awk -v node=$this_node '{printf("%s,%s,%s,%s,%s\n",node,$1,$2,$4,$5)}'
    fi
else
    echo "$this_node,$filesystem_name,NA,NA,NA"
fi
exit 0
```

## Specialized Wrapper Scripts

The framework includes specialized wrapper scripts in `scripts/utils/` for common monitoring tasks. These scripts wrap the main diagnostics engine with specific configurations and email reporting.

### Certificate Validity Monitor (`get_cert_dates_region.sh`)

**Purpose**: Monitor SSL/TLS certificate expiration across regions

**Usage**:
```bash
# Single region, primary pods
./get_cert_dates_region.sh hollywood

# Single region, legacy pods
./get_cert_dates_region.sh hollywood legacy

# Single region, all pods
./get_cert_dates_region.sh hollywood all

# Multiple regions
./get_cert_dates_region.sh hollywood,westminister,samurai all
```

**Output Columns**:
- RegionName
- CertType
- Plugin
- Command
- RPM_Version
- FileName
- ValidFrom (DD/Mon/YYYY)
- ValidUntil (DD/Mon/YYYY)

### Database Lock Monitor (`db_lock_diag_region.sh`)

**Purpose**: Detect leftover database lock files that may prevent operations

**Usage**: Same pattern as certificate monitor

**Output**: Reports presence/absence of `dbck.lock` files

### Docker Filesystem Monitor (`docker_fs_size_region.sh`)

**Purpose**: Monitor Docker partition usage across nodes

**Output Columns**:
- RegionName
- NodeName
- Plugin
- Command
- Total
- Available
- UsedPercent

### JVM Log Statistics (`jvmlog_stats_region.sh`)

**Purpose**: Count JFR and GC log files for capacity planning

**Output Columns**:
- RegionName
- NodeName
- Plugin
- Command
- JFR_Logs (count)
- GC_Logs (count)

### Wrapper Script Pattern

All wrapper scripts follow this pattern:

```bash
#!/usr/bin/env bash

function initialise(){
    THIS_UNIQ_ID=$$
    # Set paths
    DIAGNOSTIC_SCRIPT=${DIAGNOSTICS_DIR}/scripts/bin/run_diagnostics.sh
    INPUT_SCRIPT="target_plugin_script.sh"
    # Configure email
    EMAILIDS="ops-team@company.com"
    # Source libraries
    source ${DIAGNOSTICS_DIR}/scripts/lib/common_utils_functions.sh
    source ${DIAGNOSTICS_DIR}/scripts/lib/html_generator.sh
}

function parse_output_data(){
    # Transform CSV output
    # Generate HTML report
    # Send email
    render_email_message $temp_csv_file "$subject" "$html_msg1" "$html_msg2"
}

# Main execution
initialise "plugin_script.sh"
regions=$1
case "${2,,}" in
    all) nodes="--node=primarypod,legacypod";;
    legacy) nodes="--node=legacypod";;
    *) nodes="--node=primarypod";;
esac
run_command_on_regions $regions $nodes
wait $(jobs -lr | awk '{printf("%s ",$2)}')
parse_output_data $regions
```

## Architecture

### Execution Flow

1. **Initialization**
   - Parse command-line options
   - Validate inputs
   - Check Bash version (≥5.0 required)
   - Initialize arrays and variables

2. **Region Discovery**
   - Resolve geography to regions (if using `-g`)
   - Validate region names against configuration
   - Check SSH connectivity for remote regions

3. **Node Discovery**
   - Query Ansible inventory for node lists
   - Filter by node groups if specified
   - Handle both local and remote inventory access

4. **Plugin Execution**
   - **Local regions**: Direct SSH to nodes
   - **Remote regions**: 
     1. Transfer plugins via rsync to bastion
     2. SSH through bastion to target nodes
     3. Execute scripts via stdin redirection

5. **Output Generation**
   - Collect JSON output from each execution
   - Parse metadata from plugin scripts
   - Transform to requested format (JSON/CSV/HTML)
   - Clean up temporary files

### Local vs Remote Execution

**Local Regions** (matching `LOCAL_POD_PATTERN`):
- Direct SSH access to nodes
- No plugin transfer required
- Faster execution

**Remote Regions**:
- SSH through bastion host
- Plugin directory synced to bastion
- Double SSH hop: local → bastion → node

```
Local:  [Script] --SSH--> [Node]
Remote: [Script] --SSH--> [Bastion] --SSH--> [Node]
```

### Data Flow

```
┌──────────────┐
│ User Command │
└──────┬───────┘
       │
       v
┌──────────────────┐
│ Parse Options    │
│ & Validate Input │
└──────┬───────────┘
       │
       v
┌──────────────────┐
│ Discover Nodes   │
│ (Ansible)        │
└──────┬───────────┘
       │
       v
┌──────────────────┐    ┌─────────────────┐
│ Execute Plugins  │───>│ Transfer Plugins│
│ (SSH)            │    │ (Remote Only)   │
└──────┬───────────┘    └─────────────────┘
       │
       v
┌──────────────────┐
│ Collect Results  │
│ (JSON)           │
└──────┬───────────┘
       │
       v
┌──────────────────┐
│ Transform Output │
│ (JSON/CSV/HTML)  │
└──────┬───────────┘
       │
       v
┌──────────────────┐
│ Log & Display    │
└──────────────────┘
```

## Output Formats

### JSON Format

```json
[
  {
    "region": "hollywood",
    "node": "hollywood-prod-web-1",
    "plugin": "system",
    "command": "filesystem_usage.sh",
    "description": "Shows filesystem usage",
    "category": "Stats",
    "output": "/dev/sda1,100G,45G,55%"
  }
]
```

### CSV Format

```csv
RegionName,NodeName,Plugin,Command,RESULT1,RESULT2,RESULT3
hollywood,web-1,system,filesystem_usage.sh,/dev/sda1,100G,55%
hollywood,web-2,system,filesystem_usage.sh,/dev/sda1,100G,62%
```

### HTML Format

Generated HTML includes:
- Styled table with hover effects
- Sortable columns
- Color-coded status indicators
- Email-friendly formatting

## Logging

### Log File Location

```
logs/run_diagnostics.sh_DDMMYYYY_PID.log
```

### Log Levels

- **INFO**: Normal operational messages
- **ERROR**: Error conditions requiring attention
- **WARN**: Warning messages
- **DEBUG**: Detailed debugging information (requires `-d` flag)

### Log Format

```
[YYYY-MM-DD HH:MM:SS][LEVEL][SCRIPT_NAME]: Message
```

### Debug Mode

Enable with `-d` or `--debug`:
```bash
./run_diagnostics.sh -r hollywood -p system -d
```

Debug mode logs:
- Function entry/exit
- Variable values
- SSH command construction
- File operations
- Ansible queries

## Error Handling

### Exit Codes

- `0`: Success
- `1`: General error (missing regions, connection failure, node discovery failure)
- `2`: Invalid option or missing required arguments

### Error Scenarios

**Bash Version Check**:
```
You have bash 4.4 installed. You will need atleast version 5 and above.
```

**No Regions Provided**:
```
No regions provided. We need atleast one region to run diagnostics.
```

**SSH Connection Failure**:
```
Login failure to region. Exiting
```

**Plugin Transfer Failure**:
```
Transferring plugins FAILED. Error Code: 1
```

**Node Discovery Failure**:
```
Getting nodes list failed.
```

### Error Recovery

- Failed scripts output `[FAILED]: Error Code: X`
- Non-applicable checks output `Not-Applicable`
- Individual failures don't stop batch execution
- All errors logged with timestamps and context

## Best Practices

### General Usage

1. **Test locally first**: Always test on local/dev regions before production
2. **Use specific plugins**: Target specific plugins rather than running all
3. **Filter node groups**: Reduce execution time by specifying relevant groups
4. **Enable debug for troubleshooting**: Use `-d` to understand execution flow
5. **Review logs**: Always check log files after execution

### Plugin Development

1. **Include complete metadata**: Ensure all metadata fields are populated
2. **Handle edge cases**: Check for prerequisites before execution
3. **Return structured output**: Use consistent CSV format for parsing
4. **Use meaningful names**: Script names should indicate their purpose
5. **Test on representative nodes**: Verify against different node types

### Operational Monitoring

1. **Schedule wrapper scripts**: Use cron for regular monitoring tasks
2. **Set up email alerts**: Configure `EMAILIDS` in wrapper scripts
3. **Archive historical reports**: Keep CSV/HTML outputs for trend analysis
4. **Monitor execution time**: Track diagnostic runtime for capacity planning
5. **Review filtered data**: Check `FAILED` and `NA` entries separately

### Security Considerations

1. **Protect SSH keys**: Ensure proper permissions on private keys
2. **Review log permissions**: Logs may contain sensitive information
3. **Use sudo judiciously**: Only elevate privileges when necessary
4. **Validate input**: Scripts should sanitize user-provided arguments
5. **Audit bastion access**: Monitor SSH sessions to bastion hosts

## Troubleshooting

### Common Issues

**Bash Version Error**:
```bash
# Check version
bash --version

# Upgrade on RHEL/CentOS
sudo yum install bash
```

**Ansible Not Found**:
```bash
# Install Ansible
sudo yum install ansible
# or
sudo pip install ansible
```

**JQ Not Installed**:
```bash
sudo yum install jq
```

**SSH Key Issues**:
```bash
# Check SSH agent
ssh-add -l

# Add key
ssh-add ~/.ssh/id_rsa

# Test connection
ssh -v hostname
```

**Ansible Inventory Errors**:
```bash
# Test inventory locally
ansible-inventory -i ansible/inventory/hollywood --list

# Test on remote bastion
ssh bastion-hollywood "ansible-inventory --list"
```

**Plugin Transfer Failures**:
```bash
# Check network connectivity
ping bastion-hollywood

# Test rsync
rsync -rhq --delete -e ssh plugins/ bastion-hollywood:test/

# Check disk space on bastion
ssh bastion-hollywood "df -h"
```

**Empty Results**:
- Verify plugin scripts have execute permissions
- Check if nodes match expected patterns in scripts
- Review debug logs for "Not-Applicable" messages
- Ensure Ansible groups match `-n` arguments

### Debug Workflow

1. **Enable debug mode**: Add `-d` flag
2. **Review log file**: Check `logs/run_diagnostics.sh_*.log`
3. **Test SSH manually**: Verify connectivity to regions/nodes
4. **Run ansible commands**: Test inventory queries directly
5. **Execute plugin locally**: Test script on target node
6. **Check permissions**: Ensure sudo access where needed

## Performance Optimization

### Execution Time Factors

- Number of regions: Linear impact
- Number of nodes per region: Linear impact
- Number of plugins: Linear impact
- Network latency: Significant for remote regions
- Plugin complexity: Variable impact

### Optimization Strategies

1. **Parallel execution**: Run multiple regions simultaneously
```bash
for region in hollywood westminister samurai; do
    ./run_diagnostics.sh -r $region -p system &
done
wait
```

2. **Selective targeting**: Use specific node groups
```bash
# Instead of all nodes
./run_diagnostics.sh -r hollywood

# Target specific groups
./run_diagnostics.sh -r hollywood -n controlplane,database
```

3. **Plugin caching**: Remote plugin transfers are cached on bastions

4. **Output format**: JSON is fastest, HTML adds processing overhead

## Integration Examples

### Cron Scheduling

```bash
# Daily certificate check at 2 AM
0 2 * * * /path/to/get_cert_dates_region.sh hollywood,westminister all

# Hourly disk usage check
0 * * * * /path/to/docker_fs_size_region.sh hollywood

# Weekly comprehensive check
0 3 * * 0 /path/to/run_diagnostics.sh -r hollywood -p system -j -o /reports/weekly.json
```

### CI/CD Pipeline

```bash
#!/bin/bash
# Post-deployment health check

./run_diagnostics.sh -r $DEPLOY_REGION -p application -j -o health.json

# Parse results
ERRORS=$(jq '[.[] | select(.output | contains("ERROR"))] | length' health.json)

if [ "$ERRORS" -gt 0 ]; then
    echo "Health check failed with $ERRORS errors"
    exit 1
fi

echo "Health check passed"
```

### Monitoring Integration

```bash
#!/bin/bash
# Prometheus metrics exporter

./run_diagnostics.sh -r hollywood -p system -j -o /tmp/metrics.json

# Transform to Prometheus format
jq -r '.[] | select(.plugin=="system" and .command=="filesystem_usage.sh") | 
"disk_usage_percent{region=\"\(.region)\",node=\"\(.node)\"} \(.output | split(",")[4] | rtrimstr("%"))"' \
/tmp/metrics.json > /var/lib/node_exporter/diagnostics.prom
```

## Version History

### v1.00 (Current)
- Initial release
- Multi-region diagnostic execution
- Plugin-based architecture
- Local and remote execution support
- Multiple output formats (JSON, CSV, HTML)
- Dynamic node discovery via Ansible
- Geography-based region grouping
- Email notification support
- Specialized wrapper scripts

## License

GNU General Public License v3.0 - See LICENSE file for details

## Support

For issues or questions:

1. Enable debug mode (`-d`) for detailed execution traces
2. Review log file in `logs/` directory
3. Verify SSH connectivity and Ansible inventory
4. Check plugin script permissions and metadata
5. Test individual components (SSH, Ansible, plugins) separately

## Contributing

### Adding New Plugins

1. Create plugin directory under `plugins/`
2. Add scripts with proper metadata blocks
3. Test on representative nodes
4. Document in plugin README (if complex)
5. Update main documentation

### Adding Wrapper Scripts

1. Follow existing wrapper script pattern
2. Use consistent naming: `*_region.sh`
3. Include parse_output_data function
4. Configure email notifications
5. Add usage examples to documentation

### Code Standards

- Use shellcheck for linting
- Include error handling
- Add debug logging
- Follow existing naming conventions
- Document complex logic
- Test on multiple node types

## Acknowledgments

- Infrastructure team for requirements and testing
- Ansible community for inventory patterns
- Contributors to jq, rsync, and other dependencies