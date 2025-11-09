#!/bin/bash
set -euo pipefail

DAYS=7
REPORT="aws-cost-$(date +%Y%m%d).json"

analyze_service() {
  local service="$1"
  aws ce get-cost-and-usage \
    --time-period Start=$(date -d "$DAYS days ago" +%Y-%m-%d),End=$(date +%Y-%m-%d) \
    --granularity DAILY \
    --metrics "UnblendedCost" \
    --group-by Type=DIMENSION,Key=SERVICE \
    --filter "{\"Dimensions\":{\"Key\":\"SERVICE\",\"Values\":[\"$service\"]}}" \
    --output json > "/tmp/cost-$service.json" &
}

services=("AmazonEC2" "AmazonS3" "AWSLambda" "AmazonRDS")
for s in "${services[@]}"; do
  analyze_service "$s"
done
wait

jq -s 'add' /tmp/cost-*.json > "$REPORT"
echo "AWS expense report: $REPORT"
