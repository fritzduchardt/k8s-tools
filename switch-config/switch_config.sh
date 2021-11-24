#!/usr/bin/env bash

cluster=${1:?Please provide cluster}
dir=$(dirname "$0")
config_file=$dir/context-config

declare -A configMap
declare -A titleMap

while IFS= read -r line; do
  short=${line%%#*}
  seg=${line#*#}
  long=${seg%#*}
  context=${line##*#}
  configMap[$short]=$context
  titleMap[$short]=$long
done < "$config_file"

kubeconfig=${configMap[$cluster]}
title=${titleMap[$cluster]}

if [ -z "$title" ]; then
  echo "Cluster $cluster not set up" >&2
else
  echo "Exporting KUBECONFIG=$kubeconfig"
  echo "Switching to cluster=$title"

  export KUBECONFIG="$kubeconfig"
fi
