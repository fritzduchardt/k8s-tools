#!/usr/bin/env bash

set -eo pipefail

SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"

# Prints usage information and exits.
usage() {
    cat <<EOF
Usage: "$0" <namespace>

Removes finalizers and then deletes ArgoCD Custom Resources (Applications,
ApplicationSets, and AppProjects) from the specified Kubernetes namespace.

This is a destructive operation that should be used with caution, for example,
when a namespace is stuck in a terminating state due to ArgoCD finalizers.

ARGUMENTS:
  <namespace>   The Kubernetes namespace to clean up. Required.
EOF
    exit 1
}

# cleanup_resources removes finalizers and deletes all instances of a given resource type in a namespace.
# Arguments:
#   $1: The resource type (e.g., 'applications', 'applicationsets').
#   $2: The namespace.
cleanup_resources() {
    local resource_type="$1"
    local namespace="$2"

    log::info "--- Processing resource type: \"$resource_type\" in namespace '$namespace' ---"

    # Get resource names. If the command returns no names, the loop won't execute.
    local resources
    resources=$(kubectl get "$resource_type" -n "$namespace" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || true)

    if [[ -z "$resources" ]]; then
        log::info "No '$resource_type' resources found in namespace '$namespace'."
        return
    fi

    local name
    for name in $resources; do
        log::info "Processing \"$resource_type\" '$name'..."

        log::info "  -> Removing finalizer..."
        # The patch command fails if there are no finalizers. We check the exit code
        # to handle the expected error without stopping the script due to `set -e`.
        if ! kubectl patch "$resource_type" "$name" -n "$namespace" --type='json' -p='[{"op": "remove", "path": "/metadata/finalizers"}]' &>/dev/null; then
            log::warn "     Could not remove finalizer from \"$resource_type\" '$name'. It might not have one or was already deleted."
        fi

        log::info "  -> Deleting resource..."
        # --ignore-not-found is used in case the resource was deleted between the 'get' and 'delete' operations.
        kubectl delete "$resource_type" "$name" -n "$namespace" --ignore-not-found=true
    done

    log::info "--- Finished processing resource type: \"$resource_type\" ---"
}

# verify_namespace checks if the specified namespace exists
verify_namespace() {
    local namespace="$1"

    if ! kubectl get namespace "$namespace" &>/dev/null; then
        log::error "Namespace '$namespace' does not exist"
        exit 1
    fi
}

# Main function to orchestrate the cleanup process.
main() {
    if [[ "$1" == "-h" || "$1" == "--help" || -z "$1" ]]; then
        usage
    fi
    local namespace="$1"

    log::info "Starting ArgoCD CR cleanup in namespace: '$namespace'"

    # Verify namespace exists
    verify_namespace "$namespace"

    # Define the ArgoCD resource types to be processed.
    local -r resource_types=("applications.argoproj.io" "applicationsets.argoproj.io" "appprojects.argoproj.io")

    local rt
    for rt in "${resource_types[@]}"; do
        cleanup_resources "$rt" "$namespace"
    done

    log::info "Cleanup of ArgoCD CRs in namespace '$namespace' completed successfully."
}

# Ensures the script is not being sourced and executes the main function with all provided arguments.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
