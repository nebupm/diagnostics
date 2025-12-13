# Diagnostics Script

A comprehensive bash-based diagnostics tool for running automated checks across infrastructure regions, nodes, and plugins. This script enables remote and local execution of diagnostic plugins across distributed infrastructure environments.

## Overview

This tool provides a flexible framework for executing diagnostic scripts (organized as plugins) across multiple regions and node groups. It supports both local and remote execution via SSH, with results output in multiple formats (JSON, CSV, HTML).

## Requirements

- **Bash**: Version 5.0 or higher
- **Dependencies**:
  - `jq` - JSON processing
  - `ansible` - Inventory management and node discovery
  - `ssh` - Remote execution
  - `rsync` - Plugin file transfer

## Directory Structure

```
diagnostics/
├── scripts
│   └── bin/
│       ├── run_diagnostics.sh          # Main script
│   └── lib/
│       ├── logger.sh
│       ├── html_generator.sh
│       ├── usage_help_functions.sh
│       └── common_utils_functions.sh
├── plugins/
│   └── [plugin_directories]/
│       └── [diagnostic_scripts]
├── config/
│   └── regions.json
└── logs/
    └── diagnostics.sh_DDMMYYYY_PID.log
```

## Usage

```bash
scripts/bin/run_diagnostics.sh [OPTIONS]
```

### Common Options

| Option | Long Form | Description |
|--------|-----------|-------------|
| `-r` | `--region` | Specify region(s) (comma-separated) |
| `-g` | `--geo` | Specify geography/geo(s) (comma-separated) |
| `-n` | `--node` | Specify node(s) or node group(s) (comma-separated) |
| `-p` | `--plugin` | Specify plugin(s) to run (comma-separated) |
| `-s` | `--script` | Specify individual script(s) to run (comma-separated) |
| `-a` | `--args` | Pass arguments to scripts (comma-separated) |
| `-o` | `--output` | Output file path |
| `-j` | `--json` | Enable JSON output format |
| `-c` | `--csv` | Enable CSV output format |
| `-x` | `--html` | Enable HTML output format |
| `-d` | `--debug` | Enable debug logging |
| `-v` | `--version` | Show version information |
| `-h` | `--help` | Show help message |

### List Operations

| Option | Long Form | Description |
|--------|-----------|-------------|
| `-R` | `--listregions` | List all available regions |
| `-G` | `--listgeos` | List all geographies (optionally filter by geo) |
| `-N` | `--listnodes` | List nodes in specified region(s) |
| `-P` | `--listplugins` | List all available plugins |
| `-S` | `--listscripts` | List all available scripts with descriptions |

## Examples

### List Available Resources

```bash
# List all regions
./scripts/bin/run_diagnostics.sh -R

# List all geographies
./scripts/bin/run_diagnostics.sh -G

# List geographies and their regions for specific geos
./scripts/bin/run_diagnostics.sh -G us,eu

# List nodes in a specific region
./scripts/bin/run_diagnostics.sh -N region-name

# List all available plugins
./scripts/bin/run_diagnostics.sh -P

# List all scripts with descriptions
./scripts/bin/run_diagnostics.sh -S
```

### Run Diagnostics

```bash
# Run all plugins on all nodes in a region
./scripts/bin/run_diagnostics.sh -r region-name

# Run specific plugin on all nodes in multiple regions
./scripts/bin/run_diagnostics.sh -r region1,region2 -p network-checks

# Run multiple plugins on specific node groups
./scripts/bin/run_diagnostics.sh -r region-name -n controlplane,dataplane -p system-info,disk-usage

# Run specific script with arguments
./scripts/bin/run_diagnostics.sh -r region-name -n instance -s check_service.sh -a "nginx,active"

# Run diagnostics across a geography
./scripts/bin/run_diagnostics.sh -g us -p health-checks
```

### Output Formats

```bash
# Output results as JSON
./scripts/bin/run_diagnostics.sh -r region-name -p system-info -j -o results.json

# Output results as CSV
./scripts/bin/run_diagnostics.sh -r region-name -p system-info -c -o results.csv

# Output results as HTML
./scripts/bin/run_diagnostics.sh -r region-name -p system-info -x -o results.html

# Enable debug logging
./scripts/bin/run_diagnostics.sh -r region-name -p system-info -d
```

## Plugin Development

Plugins are organized in directories under the `plugins/` folder. Each plugin directory contains one or more executable scripts.

### Plugin Script Structure

Each diagnostic script must include metadata headers:

```bash
#!/usr/bin/env bash

##METADATA-START
##@ Command: script_name
##@ Description: What this script checks
##@ Category: system|network|storage
##@ Author: Your Name
##METADATA-END

# Script logic here
# Output results to stdout
# Return "Not-Applicable" if check doesn't apply to this node
```

### Valid Node Patterns

Scripts can target specific node types:
- `instance`
- `pod`
- `web`
- `activemq`
- `control`
- `controlplane`
- `dataplane`
- `region`
- `developer`
- `test`
- `all`

## Architecture

### Execution Flow

1. **Initialization**: Parse options, validate inputs, initialize arrays
2. **Region Discovery**: Identify target regions from geo/region inputs
3. **Node Discovery**: Get node lists from Ansible inventory
4. **Plugin/Script Execution**:
   - **Local regions**: Direct SSH execution
   - **Remote regions**: Transfer plugins via rsync, execute through bastion
5. **Output Generation**: Collect results and format as JSON/CSV/HTML

### Local vs Remote Execution

- **Local regions**: Can be accessed directly without bastion hosts
- **Remote regions**: Require SSH through bastion hosts with plugin file transfer

## Output Format

Results are captured in JSON format with the following structure:

```json
{
  "region": "region-name",
  "node": "node-name",
  "plugin": "plugin-name",
  "command": "script-name",
  "output": "command output",
  "description": "script description",
  "category": "script category"
}
```

## Configuration

### SSH Configuration

The script uses SSH configurations defined in the environment. SSH options should be set via the `SSH_OPTIONS` variable, and SSH config files should be available in `SSH_CONFIG_FILE` array.
This script will look for ssh config file in your ~/.ssh folder.

### Region Configuration

Regions are defined in `config/regions.json` with geography mappings. The JSON structure includes:
- Geography codes (geo identifiers)
- Region names
- Region types (OCI-native, etc.)

### Ansible Inventory

Ansible inventory files are expected at:
- Local regions: `${WORKING_DIR}/../ansible/inventory/[region]`
- Remote regions : The ones that need a bastion host. Its expected that there is an ansible inventory present on the bastion.
- The script uses these inventories to discover nodes and node groups dynamically

### Environment Variables

The script sets up the following key variables:
- `THIS_UNIQ_ID`: Process ID for tracking
- `WORKING_DIR`: Base directory (3 levels up from script location)
- `PLUGINS_DIR`: `${WORKING_DIR}/plugins`
- `LOG_DIR`: `${WORKING_DIR}/logs`
- `REGION_CONFIG_FILE`: `${WORKING_DIR}/config/regions.json`
- `LOCAL_POD_PATTERN`: Pattern to identify local regions (defined in common_utils_functions.sh)

## Logging

All execution output is logged to both stdout and a log file:
```
logs/diagnostics.sh_DDMMYYYY_PID.log
```

The script uses the `tee` command to duplicate output, ensuring you see results in real-time while maintaining a complete log file.

Debug messages are controlled by the `-d` flag and use the `print_debug_message` function from the logger library.

## Error Handling

- **Invalid options**: Trigger usage help messages
- **Missing required parameters**: Show option-specific help and exit with code 2
- **Failed script executions**: Logged with error codes, temporary files capture STDERR
- **Non-applicable checks**: Scripts can return "Not-Applicable" to indicate the check doesn't apply
- **Bash version check**: Script exits if Bash version is below 5.0
- **Region validation**: Checks if regions exist and are accessible
- **Node discovery failures**: Returns error code 1 and logs failure message
- **Plugin transfer failures**: For remote regions, logs rsync errors with status codes

### Exit Codes

- `0`: Success
- `1`: General error (missing regions, node discovery failure, etc.)
- `2`: Invalid option usage or missing required arguments

## Best Practices

1. **Test locally first**: Run diagnostics on local/dev regions before production
2. **Use specific plugins**: Target specific plugins rather than running all to reduce execution time
3. **Filter node groups**: Specify relevant node groups to avoid unnecessary checks
4. **Enable debug mode**: Use `-d` for troubleshooting issues
5. **Review output**: Check generated files for errors before acting on results
6. **Check logs**: Always review the log file in `logs/` for complete execution details
7. **Validate plugin metadata**: Ensure all plugin scripts have proper `##METADATA` blocks
8. **Use geography filtering**: For multi-region operations, use `-g` to target entire geographies
9. **Handle remote regions**: Ensure rsync and SSH work properly for remote region access
10. **Monitor temp files**: The script creates temporary files with `mktemp`; they're cleaned up automatically

## Troubleshooting

### Common Issues

**Bash version error**:
```
You have bash X.X installed. You will need atleast version 5 and above.
```
Solution: Upgrade to Bash 5.0+

**No regions provided**:
```
No regions provided. We need atleast one region to run diagnostics.
```
Solution: Specify region with `-r` or geography with `-g`

**Plugin not found**:
```
Plugin X is not a valid Plugin. It must be a folder.
```
Solution: Verify plugin exists in `plugins/` directory and is a folder, not a file

**Invalid node pattern**:
```
Node: X is not in Valid pattern: instance|pod|web|activemq|control|all|controlplane|dataplane|region|developer|test
```
Solution: Use valid node types or use `-N` to list available nodes for a region

**SSH connection failures**: 
- Check SSH config files exist and are properly formatted
- Verify bastion host connectivity for remote regions
- Ensure SSH keys are properly configured
- Check `SSH_OPTIONS` variable is set correctly

**Ansible inventory errors**:
```
Getting nodes list failed on remote region.
```
Solution: 
- Verify Ansible is installed and the bastion is accessible
- Check inventory files exist at expected locations
- Ensure proper permissions on inventory files
- For remote regions, verify Ansible is installed on the bastion host

**Plugin transfer failures** (remote regions):
```
Transferring plugins FAILED. Error Code: X
```
Solution:
- Check network connectivity to bastion host
- Verify rsync is installed on both local and remote systems
- Ensure proper SSH permissions for file transfer
- Check disk space on remote bastion host

**Script not found in plugins**:
```
Script: X is not present in $PLUGINS_DIR.
```
Solution: Verify the script exists in one of the plugin directories with correct name

**JSON parsing errors**: Ensure `jq` is installed and `config/regions.json` is valid JSON

## Advanced Features

### Dynamic Node Discovery

When no nodes are specified with `-n`, the script automatically discovers all available nodes in each region using Ansible inventory:
```bash
# Will discover and run on all nodes in the region
./scripts/bin/run_diagnostics.sh -r my-region -p system-info
```

### Parallel Region Processing

The script processes regions sequentially but can handle multiple regions in a single run:
```bash
# Process multiple regions
./scripts/bin/run_diagnostics.sh -r region1,region2,region3 -p health-checks
```

### Plugin Transfer Optimization

For remote regions, the script uses `rsync` with the `--delete` flag to:
- Efficiently sync only changed files
- Remove obsolete files on remote hosts
- Minimize transfer time

### Signal Handling

The script traps EXIT and SIGINT signals for clean shutdown:
- `script_exit`: Cleanup function on normal exit
- `script_interrupt`: Handler for Ctrl+C interruption

### Temporary File Management

All temporary files are created with `mktemp` for security and automatically cleaned up:
- JSON processing files
- CSV intermediate files
- Command execution buffers

### Output Filtering

Command outputs automatically filter:
- Banner messages (defined in `BANNER_MESSAGE`)
- "Last login" SSH messages
- Empty lines in CSV generation

## Performance Considerations

1. **Node Group Filtering**: Use specific node groups to reduce execution time
2. **Plugin Selection**: Run only necessary plugins instead of all
3. **Remote Transfers**: Plugin transfers are cached on bastion hosts; only changed files sync
4. **Parallel Execution**: Consider running multiple script instances for different regions
5. **Output Format**: JSON is fastest; HTML generation adds processing overhead

## Security Notes

- The script disables StrictHostKeyChecking via `SSH_OPTIONS` for automation
- All SSH operations use key-based authentication
- Remote plugin execution uses bash stdin redirection for security
- Temporary files use secure `mktemp` for random naming
- Log files may contain sensitive command outputs; review permissions

## Integration Examples

### CI/CD Pipeline Integration

```bash
#!/bin/bash
# Run diagnostics as part of deployment validation
./scripts/bin/run_diagnostics.sh -r production-region -p health-checks -j -o /tmp/health.json
if [ $? -eq 0 ]; then
    echo "Health checks passed"
    # Parse JSON results for specific checks
    jq '.[] | select(.plugin=="health-checks")' /tmp/health.json
else
    echo "Health checks failed"
    exit 1
fi
```

### Monitoring Integration

```bash
#!/bin/bash
# Scheduled monitoring job
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
./scripts/bin/run_diagnostics.sh -r all-regions -p monitoring -c -o /var/log/diagnostics/${TIMESTAMP}.csv

# Process CSV for alerting
awk -F',' '$5 ~ /ERROR|CRITICAL/ {print}' /var/log/diagnostics/${TIMESTAMP}.csv | \
    mail -s "Diagnostic Alerts" ops-team@company.com
```

### Batch Processing

```bash
#!/bin/bash
# Run different plugin sets sequentially
for plugin in system-info network-checks disk-usage; do
    ./scripts/bin/run_diagnostics.sh -r my-region -n controlplane -p $plugin -j -o results_${plugin}.json
done

# Combine results
jq -s 'add' results_*.json > combined_results.json
```

## Support

For issues or questions:
1. Enable debug mode (`-d`) for detailed execution traces
2. Check the log file in `logs/` directory
3. Review SSH connectivity and Ansible inventory configuration
4. Verify plugin metadata is properly formatted

## Version

Current version: v1.00

## License

GNU GENERAL PUBLIC LICENSE Version 3, 29 June 2007

## Contributing

When adding new plugins:
1. Create a new directory under `plugins/`
2. Add executable scripts with proper metadata blocks
3. Test locally before deploying to production regions
4. Update documentation if adding new features

## Changelog

### v1.00 (Initial Release)
- Multi-region diagnostic execution
- Plugin-based architecture
- Local and remote execution support
- Multiple output formats (JSON, CSV, HTML)
- Dynamic node discovery via Ansible
- Geography-based region grouping