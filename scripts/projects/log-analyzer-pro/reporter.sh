# scripts/projects/log-analyzer-pro/reporter.sh
generate_json_report() {
  jq -n \
    --arg ts "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
    '{
      generated_at: $ts,
      total_files: (input_filename | length),
      services: [
        inputs
        | split("\t")
        | {service: .[0], errors: (.[1]|tonumber), warnings: (.[2]|tonumber), info: (.[3]|tonumber)}
      ]
    }' /tmp/.log-analyzer-tmp-*.txt
}

generate_prometheus_metrics() {
  cat /tmp/.log-analyzer-tmp-*.txt | awk '
  {
    print "log_errors_total{service=\"" $1 "\"} " $2
    print "log_warnings_total{service=\"" $1 "\"} " $3
    print "log_info_total{service=\"" $1 "\"} " $4
  }'
}
