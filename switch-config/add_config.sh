#!/usr/bin/env bash
set -euo pipefail
dir=$(dirname "$0")
config_file=$dir/context-config

short=${1?Please provide context shortcut}
long=${2?Please provide context long version}
path=${3?Please provide path to kube config file}

count=$(grep -c "$short#" "$config_file" || true)

if [ "$count" -gt 0 ]; then
  echo "Config for \"${short}\" does already exist" >&2
  exit 1
fi

echo -e "${short}#${long}#${path}" >> "$config_file"

echo "Context was added"