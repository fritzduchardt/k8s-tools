#!/usr/bin/env bash

source "../lib/log.sh"
source "../lib/utils.sh"

ns_prefix="${1:?Provide namespace prefix}"
shift 1

while IFS= read -r ns; do
  ns="${ns#*/}"
  log::info "Switching to namespace: $ns"
  kubectl config set-context --current --namespace="$ns"
  "$@"
done < <(kubectl get ns -oname | grep -o "^namespace/$ns_prefix.*")
