#!/usr/bin/env bash
set -eo pipefail

usage() {
  echo "Usage: $(basename "$0") SERVICE_NAME LAUNCH_IN_NEW_TERMINAL"
  echo
  echo "Opens Port-Forward to specified service name. Service name relates to configuration in port-forward-config file."
  echo "Provides flag to open Port Forward in new terminal"
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
  new_terminal="${2:-true}"
  dir="$(dirname "$0")"
  config_file="$dir/port-forward-config"
  cluster="$(kubectl config current-context)"

  config_line="$(grep "${service}#" "$config_file" || true)"
  if [ -z "$config_line" ]; then
    echo "No config found for service $service" >&2
    exit 1
  fi

  if [ "$new_terminal" = true ]; then
    gnome-terminal --title "${KUBECONFIG##*/} - ${cluster^} - ${service^}" -- $(dirname "$0")/port_forward.sh "$service"
  else
    $(dirname "$0")/port_forward.sh "$service"
  fi
fi
