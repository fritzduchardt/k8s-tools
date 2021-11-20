#!/usr/bin/env bash

set -exuo pipefail

service=${1:-argocd}
dir=$(dirname "$0")
config_file=$dir/port-forward-config

config_line=$(grep "${service}#" "$config_file")
config_arr=(${config_line//#/ })
path=${config_arr[1]}
ports=${config_arr[2]}
namespace=${config_arr[3]}

while true; do
  echo "Starting Port Forwarding to Service: $path within Namespace: $namespace and Port-Mapping: $ports"
  kubectl port-forward "$path" -n "$namespace" "$ports"
done