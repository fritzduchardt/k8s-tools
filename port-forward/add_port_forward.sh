#!/usr/bin/env bash
set -euo pipefail
dir=$(dirname "$0")
config_file=$dir/port-forward-config

name=${1?Please provide port-forward shortcut}
path=${2?Please provide path to service}
ports=${3?Please provide port mapping}
namespace=${4?Please provide namespace}

count=$(grep -c "$name" "$config_file" || true)

if [ "$count" -gt 0 ]; then
  echo "Config for \"${short}\" does already exist" >&2
  exit 1
fi

echo -e "${name}#${path}#${ports}#${namespace}" >> "$config_file"

echo "Port-forward was added"