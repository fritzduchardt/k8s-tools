#!/usr/bin/env bash

set -eo pipefail

SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"

usage() {
  echo """
Usage: $0 [options]

Options:
  -n, --namespace NAMESPACE    Kubernetes namespace where Argo CD is installed (default: argocd)
  -l, --label LABEL_SELECTOR   Label selector to identify Argo CD components (default: app.kubernetes.io/part-of=argocd)
  -h, --help                   Show this help message

Examples:
  $0
  $0 -n argocd
  $0 --namespace argocd --label 'app.kubernetes.io/part-of=argocd'
"""
}

rollout_restart_all() {
  local namespace="$1"
  local label_selector="$2"
  local resources_list
  local resource

  log::info "Restarting Argo CD components in namespace '$namespace' matching selector '$label_selector'"

  # Get all deployments, statefulsets and daemonsets matching the selector
  resources_list="$(lib::exec "$KUBECTL_BIN" -n "$namespace" get deploy,statefulset,daemonset -l "$label_selector" -o name 2>/dev/null || true)"

  if [[ -z "$resources_list" ]]; then
    log::warn "No Argo CD components found in namespace '$namespace' with selector '$label_selector'"
    return 0
  fi

  log::debug "Found resources: $resources_list"

  # Iterate over each resource and issue a rollout restart
  while IFS= read -r resource; do
    if [[ -z "$resource" ]]; then
      continue
    fi
    log::info "Rolling out restart for $resource"
    if ! lib::exec "$KUBECTL_BIN" -n "$namespace" rollout restart \
      "$resource"; then
      log::error "Failed to restart: $resource"
    fi
  done <<<"$resources_list"

  log::info "Argo CD restart completed"
}

main() {
  local namespace="argocd"
  local label="app.kubernetes.io/part-of=argocd"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -n|--namespace)
        namespace="$2"
        shift
        shift
        ;;
      -l|--label)
        label="$2"
        shift
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        log::error "Unknown argument: $1"
        usage
        exit 1
        ;;
    esac
  done

  rollout_restart_all "$namespace" "$label"
}

main "$@"
