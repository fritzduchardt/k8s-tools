#!/usr/bin/env bash

set -eo pipefail

usage() {
  echo "Usage: $(basename "$0") SERVICE_NAME"
  echo
  echo "Opens Port-Forward to specified service name. Service name relates to configuration in port-forward-config file."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
  # parameter validation
  if [[ -z "$1" ]]
  then
    usage >&2
    exit 2
  fi

  service="$1"
  dir="$(dirname "$0")"
  config_file="$dir/port-forward-config"

  config_line="$(grep "^${service}#" "$config_file")"
  config_arr=(${config_line//#/ })
  path="${config_arr[1]}"
  ports="${config_arr[2]}"
  namespace="${config_arr[3]}"

  while true; do
    echo "Starting Port Forwarding to Service: $path within Namespace: $namespace and Port-Mapping: $ports"
    kubectl port-forward "$path" -n "$namespace" "$ports"
  done
fi
