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

if ! command -v kubectl >/dev/null 2>&1; then
    log::error "kubectl is required but not installed"
    exit 1
fi

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

while IFS= read -r namespace; do
  namespace="${namespace#*/}"
  log::info "Switching to namespace: $namespace"
  kubectl config set-context --current --namespace="$namespace"
  "$@"
done < <(kubectl get ns -oname | grep -o "^namespace/$ns_prefix.*")
