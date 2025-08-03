#!/usr/bin/env bash

set -eo pipefail

SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"

# Function to display usage information
usage() {
  cat <<EOF
Usage: $(basename "$0") RESOURCE_TYPE

Remove finalizers from Kubernetes resources of the specified type in the current namespace.

Arguments:
  RESOURCE_TYPE    The Kubernetes resource type (e.g., pod, deployment, statefulset)

Examples:
  $(basename "$0") pod
  $(basename "$0") deployment
EOF
  exit 1
}

# Function to remove finalizers from resources
remove_finalizers() {
  local resource_type="$1"
  local namespace
  namespace="$(k8s::current_namespace)"

  log::info "Removing finalizers from $resource_type resources in namespace: $namespace"

  # Get all resources of the specified type
  local resources
  resources=$(kubectl get "$resource_type" -n "$namespace" -o name 2>/dev/null)

  if [[ -z "$resources" ]]; then
    log_warn "No $resource_type resources found in namespace $namespace"
    return 0
  fi

  # Process each resource
  echo "$resources" | while read -r resource; do
    log::info "Processing $resource"

    # Check if the resource has finalizers
    local finalizers
    finalizers=$(kubectl get "$resource" -n "$namespace" -o jsonpath='{.metadata.finalizers}' 2>/dev/null)

    if [[ -z "$finalizers" || "$finalizers" == "[]" ]]; then
      log::info "No finalizers found for $resource"
      continue
    fi

    log::info "Removing finalizers from $resource"
    if lib::exec kubectl patch "$resource" -n "$namespace" -p '{"metadata":{"finalizers":[]}}' --type=merge; then
      log::info "Successfully removed finalizers from $resource"
    else
      log::error "Failed to remove finalizers from $resource"
    fi
  done
}

# Main function
main() {
  if [[ $# -ne 1 ]]; then
    usage
  fi

  local resource_type="$1"
  remove_finalizers "$resource_type"
}

# Execute main function
main "$@"
