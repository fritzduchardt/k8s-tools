#!/usr/bin/env bash

source "../lib/log.sh"
source "../lib/utils.sh"

function usage() {
    local script_name
    script_name="$(basename "$0")"
    echo "Usage: $script_name <namespace-prefix> <command>"
    echo "Example: $script_name dev kubectl get pods"
    exit 1
}

if [[ "$#" -lt 1 ]]; then
    usage
fi

if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    usage
fi

readonly ns_prefix="$1"
if [[ -z "$ns_prefix" ]]; then
    log::error "Namespace prefix is required"
    usage
fi
shift 1

if [[ "$#" -eq 0 ]]; then
    log::error "Please provide a command to execute"
    usage
fi

log::info "Using ns prefix: $ns_prefix"

while IFS= read -u 3 -r namespace; do
  namespace="${namespace#*/}"
  log::info "Switching to namespace: $namespace"
  kubectl config set-context --current --namespace="$namespace"
  if lib::exec "$@"; then
    log::info "Executed successfully"
  else
    log::error "Failed to execute"
  fi
done 3< <(lib::exec kubectl get ns -oname | lib::exec grep -o "^namespace/$ns_prefix.*")
