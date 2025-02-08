#!/usr/bin/env bash
set -euo pipefail
shopt -s globstar # enable globbing

source "../lib/log.sh"
source "../lib/utils.sh"

usage() {
  echo "Usage: $(basename "$0") SHORTCUT PATH_TO_SERVICE PORT_MAPPING NAMESPACE"
  echo
  echo "Registers new service in port-forward-config file so that a Port Forwarding to it can be opened with port-forward.sh"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then

  # parameter validation
  if [[ "$#" -ne 4 ]]
  then
    log::error "Invalid number of parameters"
    usage >&2
    exit 2
  fi

  dir="$(dirname "$0")"
  config_file="$dir/port-forward-config"

  name="$1"
  path="$2"
  ports="$3"
  namespace="$4"

  count="$(grep -c "$name" "$config_file" || true)"

  if [ "$count" -gt 0 ]; then
    echo "Config for \"${name}\" does already exist" >&2
    exit 1
  fi

  echo -e "$name#$path#$ports#$namespace" >> "$config_file"

  log::info "Port-forward was added"
fi
