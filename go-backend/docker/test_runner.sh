#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CTRL="${ROOT_DIR}/docker/test_controller.sh"
MODE="${1:-smoke}"
PEERS="${2:-${PEERS:-10}}"
RUN_BUILD="${RUN_BUILD:-0}"
REPORT_DIR="${ROOT_DIR}/docker/reports"
CONTROL_READY_TIMEOUT="${CONTROL_READY_TIMEOUT:-60}"
STAMP="$(date +%Y%m%d_%H%M%S)"
REPORT_FILE="${REPORT_DIR}/run_${MODE}_${STAMP}.json"

mkdir -p "${REPORT_DIR}"

run() {
  echo "[runner] $*"
  bash -lc "$*"
}

container_port() {
  local cid="$1"
  docker port "${cid}" 8080/tcp | awk -F: 'NR==1{print $NF}'
}

wait_control_api() {
  local deadline=$((SECONDS + CONTROL_READY_TIMEOUT))
  local ids port all_ready

  echo "[runner] waiting for peer control APIs (${CONTROL_READY_TIMEOUT}s timeout)"
  while (( SECONDS < deadline )); do
    mapfile -t ids < <(cd "${ROOT_DIR}" && docker compose ps -q --status running peer)
    if [[ ${#ids[@]} -eq 0 ]]; then
      sleep 1
      continue
    fi

    all_ready=1
    for cid in "${ids[@]}"; do
      port="$(container_port "${cid}")"
      if [[ -z "${port}" ]] || ! curl -fsS "http://127.0.0.1:${port}/status" >/dev/null 2>&1; then
        all_ready=0
        break
      fi
    done

    if [[ "${all_ready}" -eq 1 ]]; then
      echo "[runner] control APIs ready: ${#ids[@]} peer(s)"
      return 0
    fi
    sleep 1
  done

  echo "[runner] control APIs were not ready after ${CONTROL_READY_TIMEOUT}s" >&2
  return 1
}

json_string() {
  if command -v python3 >/dev/null 2>&1; then
    printf '%s' "$1" | python3 -c 'import json, sys; print(json.dumps(sys.stdin.read(), ensure_ascii=False))'
    return
  fi

  printf '%s' "$1" | awk '
    BEGIN { printf "\"" }
    {
      gsub(/\\/,"\\\\")
      gsub(/"/,"\\\"")
      gsub(/\t/,"\\t")
      if (NR > 1) printf "\\n"
      printf "%s", $0
    }
    END { printf "\"" }
  '
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
wait_control_api

list_before="$(bash "${CTRL}" list-peers || true)"
conv_before="$(bash "${CTRL}" convergence || true)"
avg_connected_before="$(collect_metric_avg connected)"
avg_routing_before="$(collect_metric_avg routing)"

mass_add_out="$(bash "${CTRL}" mass-add 2 || true)"
mass_search_out="$(bash "${CTRL}" mass-search load_track || true)"

if [[ "${MODE}" == "full" ]]; then
  churn_out="$(bash "${CTRL}" churn 3 1 || true)"
  wait_control_api
  latency_out="$(bash "${CTRL}" latency 50 1 5 || true)"
  wait_control_api
else
  churn_out="skipped"
  latency_out="skipped"
fi

conv_after="$(bash "${CTRL}" convergence || true)"
avg_connected_after="$(collect_metric_avg connected)"
avg_routing_after="$(collect_metric_avg routing)"

cat > "${REPORT_FILE}" <<EOF
{
  "mode": $(json_string "${MODE}"),
  "peers": ${PEERS},
  "generated_at": $(json_string "$(date -u +%Y-%m-%dT%H:%M:%SZ)"),
  "summary": {
    "avg_connected_before": ${avg_connected_before},
    "avg_routing_before": ${avg_routing_before},
    "avg_connected_after": ${avg_connected_after},
    "avg_routing_after": ${avg_routing_after}
  },
  "outputs": {
    "list_before": $(json_string "${list_before}"),
    "convergence_before": $(json_string "${conv_before}"),
    "mass_add": $(json_string "${mass_add_out}"),
    "mass_search": $(json_string "${mass_search_out}"),
    "churn": $(json_string "${churn_out}"),
    "latency": $(json_string "${latency_out}"),
    "convergence_after": $(json_string "${conv_after}")
  }
}
EOF

echo "[runner] Report saved: ${REPORT_FILE}"
echo "[runner] avg_connected_before=${avg_connected_before} avg_connected_after=${avg_connected_after}"
echo "[runner] avg_routing_before=${avg_routing_before} avg_routing_after=${avg_routing_after}"
