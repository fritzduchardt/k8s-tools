#!/usr/bin/env bash

source "../lib/log.sh"
source "../lib/utils.sh"

ns_prefix="${1:?Provide namespace prefix}"
shift 1

while IFS= read -r namespace; do
  namespace="${namespace#*/}"
  log::info "Switching to namespace: $namespace"
  kubectl config set-context --current --namespace="$namespace"
  "$@"
done < <(kubectl get ns -oname | grep -o "^namespace/$ns_prefix.*")
