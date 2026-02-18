#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CTRL="${ROOT_DIR}/docker/test_controller.sh"
MODE="${1:-smoke}"
PEERS="${2:-${PEERS:-10}}"
RUN_BUILD="${RUN_BUILD:-0}"
REPORT_DIR="${ROOT_DIR}/docker/reports"
STAMP="$(date +%Y%m%d_%H%M%S)"
REPORT_FILE="${REPORT_DIR}/run_${MODE}_${STAMP}.json"

mkdir -p "${REPORT_DIR}"

run() {
  echo "[runner] $*"
  bash -lc "$*"
}

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

collect_metric_avg() {
  local field="$1"
  local out
  out="$(bash "${CTRL}" convergence)"
  echo "${out}" | awk -v f="${field}" '
    BEGIN {sum=0; n=0}
    {
      for(i=1;i<=NF;i++){
        if(index($i,f"=")==1){
          split($i,a,"=");
          if(a[2] ~ /^[0-9]+$/){sum+=a[2]; n++}
        }
      }
    }
    END {if(n==0) print 0; else printf "%.2f", sum/n}
  '
}

if [[ "${RUN_BUILD}" == "1" ]]; then
  run "cd \"${ROOT_DIR}\"; docker compose up -d --build --scale peer=${PEERS}"
else
  run "cd \"${ROOT_DIR}\"; docker compose up -d --scale peer=${PEERS}"
fi
sleep 3

list_before="$(bash "${CTRL}" list-peers || true)"
conv_before="$(bash "${CTRL}" convergence || true)"
avg_connected_before="$(collect_metric_avg connected)"
avg_routing_before="$(collect_metric_avg routing)"

mass_add_out="$(bash "${CTRL}" mass-add 2 || true)"
mass_search_out="$(bash "${CTRL}" mass-search load_track || true)"

if [[ "${MODE}" == "full" ]]; then
  churn_out="$(bash "${CTRL}" churn 3 1 || true)"
  latency_out="$(bash "${CTRL}" latency 50 1 5 || true)"
else
  churn_out="skipped"
  latency_out="skipped"
fi

conv_after="$(bash "${CTRL}" convergence || true)"
avg_connected_after="$(collect_metric_avg connected)"
avg_routing_after="$(collect_metric_avg routing)"

cat > "${REPORT_FILE}" <<EOF
{
  "mode": "$(json_escape "${MODE}")",
  "peers": ${PEERS},
  "generated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "summary": {
    "avg_connected_before": ${avg_connected_before},
    "avg_routing_before": ${avg_routing_before},
    "avg_connected_after": ${avg_connected_after},
    "avg_routing_after": ${avg_routing_after}
  },
  "outputs": {
    "list_before": "$(json_escape "${list_before}")",
    "convergence_before": "$(json_escape "${conv_before}")",
    "mass_add": "$(json_escape "${mass_add_out}")",
    "mass_search": "$(json_escape "${mass_search_out}")",
    "churn": "$(json_escape "${churn_out}")",
    "latency": "$(json_escape "${latency_out}")",
    "convergence_after": "$(json_escape "${conv_after}")"
  }
}
EOF

echo "[runner] Report saved: ${REPORT_FILE}"
echo "[runner] avg_connected_before=${avg_connected_before} avg_connected_after=${avg_connected_after}"
echo "[runner] avg_routing_before=${avg_routing_before} avg_routing_after=${avg_routing_after}"

