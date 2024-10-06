#!/usr/bin/env bash

source "../lib/log.sh"
source "../lib/utils.sh"

usage() {
  echo "Usage: $(basename "$0") SERVICE_NAME LOOP [PORT_FORWARD_OPTS]"
  echo
  echo "Opens Port-Forward to specified service name. Service name relates to configuration in port-forward-config file."
}

port_forward() {
  log::info "Starting Port Forwarding to Service: $path within Namespace: $namespace and Port-Mapping: $ports"
  local -a cmd=(kubectl port-forward "$path" -n "$namespace" "$ports" --address 0.0.0.0 "${opts[@]}")
  if [[ "$bg" == "true" ]]; then
    lib::exec "${cmd[@]}" >/dev/null &
  else
    lib::exec "${cmd[@]}"
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # parameter validation
  if [[ -z "$1" ]]; then
    usage >&2
    exit 2
  fi

  service="$1"
  loop="$2"
  bg="$3"
  shift 3
  declare -a opts
  opts=("$@")
  dir="$(dirname "$0")"
  config_file="$dir/port-forward-config"

  config_line="$(grep "^${service}#" "$config_file")"
  config_arr=(${config_line//#/ })
  path="${config_arr[1]}"
  ports="${config_arr[2]}"
  namespace="${config_arr[3]}"

  if [[ -z "$namespace" ]]; then
    namespace="$(lib::exec kubectl config view --minify --template '{{ (index .contexts 0).context.namespace }}')"
  fi

  if [[ "$loop" == "true" ]]; then
    while true; do
      port_forward
    done
  else
    port_forward
  fi
fi
