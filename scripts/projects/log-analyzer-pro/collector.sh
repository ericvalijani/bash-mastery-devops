# scripts/projects/log-analyzer-pro/collector.sh
#!/usr/bin/env bash
file="$1"
[[ ! -f "$file" ]] && exit 0
parse_log_file "$file" >> /tmp/.log-analyzer-tmp-$(basename "$file").txt
