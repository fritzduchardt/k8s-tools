#!/usr/bin/env bash
set -euo pipefail

service=${1:?Please provide service}
new_terminal=${2:-true}
dir=$(dirname "$0")
config_file=$dir/port-forward-config
cluster=$(kubectl config current-context)

config_line=$(grep "${service}#" "$config_file" || true)
if [ -z "$config_line" ]; then
  echo "No config found for service $service" >&2
  exit 1
fi



if [ "$new_terminal" = true ]; then
  gnome-terminal --title "${KUBECONFIG##*/} - ${cluster^} - ${service^}" -- $(dirname "$0")/port_forward.sh "$service"
else
  $(dirname "$0")/port_forward.sh "$service"
fi
