#!/usr/bin/env bash
set -euo pipefail
dir=$(dirname "$0")
config_file=$dir/context-config

short=${1?Please provide context shortcut}

count=$(grep -c "$short" "$config_file" || true)

if [ "$count" = 0 ]; then
  echo "Config for \"${short}\" does not exist" >&2
  exit 1
fi

sed -i "/$short=/d" $config_file

echo "Context was deleted"