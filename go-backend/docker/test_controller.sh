#!/usr/bin/env bash
set -euo pipefail

COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.yml}"
SERVICE="${SERVICE:-peer}"
ENV_FILE="${ENV_FILE:-}"
AUTO_MESH="${AUTO_MESH:-1}"

die() {
  echo "[test-controller] $*" >&2
  exit 1
}

containers() {
  compose ps -q --status running "${SERVICE}"
}

compose() {
  if [[ -n "${ENV_FILE}" && -f "${ENV_FILE}" ]]; then
    docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" "$@"
    return
  fi

  if [[ -f ".env" ]]; then
    docker compose --env-file ".env" -f "${COMPOSE_FILE}" "$@"
    return
  fi

  if [[ -f "docker/.env" ]]; then
    docker compose --env-file "docker/.env" -f "${COMPOSE_FILE}" "$@"
    return
  fi

  if [[ -f "docker/.env.example" ]]; then
    docker compose --env-file "docker/.env.example" -f "${COMPOSE_FILE}" "$@"
    return
  fi

  docker compose -f "${COMPOSE_FILE}" "$@"
}

require_containers() {
  local ids
  ids="$(containers)"
  [[ -n "${ids}" ]] || die "No running containers for service '${SERVICE}'"
}

container_port() {
  local cid="$1"
  docker port "${cid}" 8080/tcp | awk -F: 'NR==1{print $2}'
}

api() {
  local cid="$1"
  local path="$2"
  local method="${3:-GET}"
  local body="${4:-}"
  local port
  port="$(container_port "${cid}")"
  if [[ -z "${port}" ]]; then
    echo "{\"error\":\"control port not published for ${cid}\"}" >&2
    return 1
  fi

  if [[ "${method}" == "GET" ]]; then
    curl -sS "http://127.0.0.1:${port}${path}"
  else
    curl -sS -X "${method}" "http://127.0.0.1:${port}${path}" \
      -H "Content-Type: application/json" \
      -d "${body}"
  fi
}

extract_connect_addr() {
  local status_json="$1"

  if has_jq; then
    echo "${status_json}" | jq -r '.addresses[] | select(startswith("/ip4/127.0.0.1/") | not)' | head -n1
    return
  fi

  if command -v python3 >/dev/null 2>&1; then
    python3 - "$status_json" <<'PY'
import json, sys
payload = json.loads(sys.argv[1])
for addr in payload.get("addresses", []):
    if isinstance(addr, str) and not addr.startswith("/ip4/127.0.0.1/"):
        print(addr)
        break
PY
    return
  fi

  echo "${status_json}" | sed -n 's/.*"\(\/ip4\/[^"]*\/p2p\/[^"]*\)".*/\1/p' | sed '/^\/ip4\/127\.0\.0\.1\//d' | head -n1
}

ensure_mesh() {
  [[ "${AUTO_MESH}" == "1" ]] || return 0
  require_containers

  mapfile -t ids < <(containers)
  [[ ${#ids[@]} -ge 2 ]] || return 0

  local seed seed_status seed_addr
  seed="${ids[0]}"
  if ! seed_status="$(api "${seed}" "/status")"; then
    return 0
  fi
  seed_addr="$(extract_connect_addr "${seed_status}")"
  [[ -n "${seed_addr}" ]] || return 0

  local cid
  for cid in "${ids[@]:1}"; do
    api "${cid}" "/connect" POST "{\"multiaddr\":\"${seed_addr}\"}" >/dev/null 2>&1 || true
  done
}

list_peers() {
  require_containers
  ensure_mesh
  while IFS= read -r cid; do
    local status
    if ! status="$(api "${cid}" "/status")"; then
      echo "${cid} -> control-api-unavailable"
      continue
    fi
    if has_jq; then
      echo "${status}" | jq --arg cid "${cid}" -c '{container: $cid, status: .}'
    else
      echo "${cid} -> ${status}"
    fi
  done < <(containers)
}

mass_add() {
  local per_peer="${1:-3}"
  require_containers

  while IFS= read -r cid; do
    local added_count=0
    for i in $(seq 1 "${per_peer}"); do
      local title artist resp sample_path track_id freq
      title="load_track_${i}_${RANDOM}"
      artist="load_artist_${RANDOM}"
      sample_path="/tmp/cotune_test_${i}_${RANDOM}.wav"
      freq=$((220 + (RANDOM % 660)))
      if ! docker exec "${cid}" bash -lc "ffmpeg -loglevel error -y -f lavfi -i sine=frequency=${freq}:duration=1 -ac 1 -ar 44100 \"${sample_path}\" >/dev/null 2>&1"; then
        echo "failed to prepare audio sample on ${cid}"
        break
      fi

      if ! resp="$(api "${cid}" "/addTrack" POST "{\"path\":\"${sample_path}\",\"title\":\"${title}\",\"artist\":\"${artist}\"}")"; then
        echo "skip addTrack on ${cid}: control-api-unavailable"
        break
      fi

      track_id="$(echo "${resp}" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p')"
      if [[ -n "${track_id}" ]]; then
        added_count=$((added_count + 1))
      else
        echo "addTrack failed on ${cid}: ${resp}"
      fi
    done
    echo "added ${added_count}/${per_peer} tracks to ${cid}"
  done < <(containers)
}

mass_search() {
  local query="${1:-load_track}"
  require_containers
  ensure_mesh
  while IFS= read -r cid; do
    local resp
    if ! resp="$(api "${cid}" "/search" POST "{\"query\":\"${query}\",\"max\":20}")"; then
      echo "${cid} search skipped: control-api-unavailable"
      continue
    fi
    local hits
    hits="$(json_get "${resp}" '.results | length')"
    echo "${cid} search hits=${hits}"
  done < <(containers)
}

mass_replicate() {
  local ctid="${1:-}"
  [[ -n "${ctid}" ]] || die "usage: mass-replicate <ctid>"
  require_containers
  while IFS= read -r cid; do
    local resp
    if ! resp="$(api "${cid}" "/replicate" POST "{\"ctid\":\"${ctid}\",\"output_path\":\"/data-root/${cid}_replica.bin\"}")"; then
      echo "replicate skipped on ${cid}: control-api-unavailable"
      continue
    fi
    case "${resp}" in
      *"\"success\":false"*|*"\"error\""*)
        echo "replicate failed on ${cid}: ${resp}"
        ;;
      *)
        echo "replicate requested on ${cid}"
        ;;
    esac
  done < <(containers)
}

churn() {
  local iterations="${1:-5}"
  local sleep_sec="${2:-5}"
  require_containers
  mapfile -t ids < <(containers)

  for _ in $(seq 1 "${iterations}"); do
    local idx cid
    idx=$((RANDOM % ${#ids[@]}))
    cid="${ids[$idx]}"
    echo "churn stop ${cid}"
    docker stop "${cid}" >/dev/null
    sleep "${sleep_sec}"
    echo "churn start ${cid}"
    docker start "${cid}" >/dev/null
    sleep "${sleep_sec}"
  done
}

latency() {
  local delay_ms="${1:-120}"
  local loss_pct="${2:-2}"
  local duration_sec="${3:-30}"
  require_containers

  while IFS= read -r cid; do
    docker exec "${cid}" bash -lc "tc qdisc replace dev eth0 root netem delay ${delay_ms}ms loss ${loss_pct}%"
    echo "netem applied on ${cid}"
  done < <(containers)

  sleep "${duration_sec}"

  while IFS= read -r cid; do
    docker exec "${cid}" bash -lc "tc qdisc del dev eth0 root || true"
    echo "netem removed on ${cid}"
  done < <(containers)
}

convergence() {
  require_containers
  ensure_mesh
  while IFS= read -r cid; do
    local status
    if ! status="$(api "${cid}" "/status")"; then
      echo "${cid} -> routing=NA providers=NA connected=NA (control-api-unavailable)"
      continue
    fi
    local routing providers connected
    routing="$(json_get "${status}" '.routing_table_size // 0')"
    providers="$(json_get "${status}" '.provider_count // 0')"
    connected="$(json_get "${status}" '.connected_peers // 0')"
    echo "${cid} -> routing=${routing} providers=${providers} connected=${connected}"
  done < <(containers)
}

provider_propagation() {
  local ctid="${1:-}"
  [[ -n "${ctid}" ]] || die "usage: provider-propagation <ctid>"
  require_containers
  local start_ts
  start_ts="$(date +%s)"

  while true; do
    local all_ok=1
    while IFS= read -r cid; do
      local resp count
      if ! resp="$(api "${cid}" "/providers?ctid=${ctid}&max=50")"; then
        all_ok=0
        continue
      fi
      count="$(json_get "${resp}" '.count // 0')"
      if [[ "${count}" -lt 1 ]]; then
        all_ok=0
      fi
    done < <(containers)

    if [[ "${all_ok}" -eq 1 ]]; then
      local end_ts
      end_ts="$(date +%s)"
      echo "provider propagation converged in $((end_ts - start_ts))s for ctid=${ctid}"
      return 0
    fi
    sleep 1
  done
}

has_jq() {
  command -v jq >/dev/null 2>&1
}

json_get() {
  local json="$1"
  local expr="$2"

  if has_jq; then
    echo "${json}" | jq -r "${expr}"
    return
  fi

  if command -v python3 >/dev/null 2>&1; then
    python3 - "$json" "$expr" <<'PY'
import json, sys
payload = json.loads(sys.argv[1])
expr = sys.argv[2]
if not isinstance(payload, dict):
    print(0)
    sys.exit(0)
if expr.startswith('.results'):
    results = payload.get('results') or []
    print(len(results))
elif 'routing_table_size' in expr:
    print(payload.get('routing_table_size', 0))
elif 'provider_count' in expr:
    print(payload.get('provider_count', 0))
elif 'connected_peers' in expr:
    print(payload.get('connected_peers', 0))
elif '.count' in expr:
    print(payload.get('count', 0))
else:
    print("")
PY
    return
  fi

  case "${expr}" in
    *routing_table_size*) echo "${json}" | sed -n 's/.*"routing_table_size":[[:space:]]*\([0-9]*\).*/\1/p' ;;
    *provider_count*) echo "${json}" | sed -n 's/.*"provider_count":[[:space:]]*\([0-9]*\).*/\1/p' ;;
    *connected_peers*) echo "${json}" | sed -n 's/.*"connected_peers":[[:space:]]*\([0-9]*\).*/\1/p' ;;
    *.count*) echo "${json}" | sed -n 's/.*"count":[[:space:]]*\([0-9]*\).*/\1/p' ;;
    *.results*) echo "${json}" | sed -n 's/.*"results":[[:space:]]*\[\(.*\)\].*/\1/p' | awk -F'},{' '{if (length($0)==0) print 0; else print NF}' ;;
    *) echo "" ;;
  esac
}

usage() {
  cat <<EOF
Usage: docker/test_controller.sh <command> [args]

Commands:
  list-peers
  mass-add [tracks_per_peer]
  mass-search [query]
  mass-replicate <ctid>
  churn [iterations] [sleep_sec]
  latency [delay_ms] [loss_pct] [duration_sec]
  convergence
  provider-propagation <ctid>
EOF
}

cmd="${1:-}"
shift || true

case "${cmd}" in
  list-peers) list_peers "$@" ;;
  mass-add) mass_add "$@" ;;
  mass-search) mass_search "$@" ;;
  mass-replicate) mass_replicate "$@" ;;
  churn) churn "$@" ;;
  latency) latency "$@" ;;
  convergence) convergence "$@" ;;
  provider-propagation) provider_propagation "$@" ;;
  *) usage; exit 1 ;;
esac

