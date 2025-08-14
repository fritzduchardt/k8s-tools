FILENAME: scripts/argo-cleanup.sh
#!/usr/bin/env bash

set -eo pipefail

SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"

# Prints usage information and exits.
usage() {
    cat <<EOF
Usage: $0 <namespace>

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

    log_info "--- Processing resource type: $resource_type in namespace '$namespace' ---"

    # Get resource names. If the command returns no names, the loop won't execute.
    # `|| true` ensures that the script does not exit if kubectl returns a non-zero status
    # (e.g., for "No resources found" message in some versions).
    local resources
    resources=$(kubectl get "$resource_type" -n "$namespace" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || true)

    if [ -z "$resources" ]; then
        log_info "No '$resource_type' resources found in namespace '$namespace'."
        return
    fi

    local name
    for name in $resources; do
        log_info "Processing $resource_type '$name'..."

        log_info "  -> Removing finalizer..."
        # The patch command fails if there are no finalizers. We redirect all output to /dev/null
        # and use `|| log_warn` to handle the expected error without stopping the script due to `set -e`.
        kubectl patch "$resource_type" "$name" -n "$namespace" --type='json' -p='[{"op": "remove", "path": "/metadata/finalizers"}]' &>/dev/null \
            || log_warn "     Could not remove finalizer from $resource_type '$name'. It might not have one or was already deleted."

        log_info "  -> Deleting resource..."
        # --ignore-not-found is used in case the resource was deleted between the 'get' and 'delete' operations.
        kubectl delete "$resource_type" "$name" -n "$namespace" --ignore-not-found=true
    done

    log_info "--- Finished processing resource type: $resource_type ---"
}

# Main function to orchestrate the cleanup process.
main() {
    if [[ "$1" == "-h" || "$1" == "--help" ]] || [ -z "$1" ]; then
        usage
    fi
    local namespace="$1"

    log_info "Starting ArgoCD CR cleanup in namespace: '$namespace'"
    log_warn "This will forcefully remove finalizers and delete ALL Applications, ApplicationSets, and AppProjects."
    log_warn "You have 5 seconds to abort (Ctrl+C)..."
    sleep 5

    # Define the ArgoCD resource types to be processed.
    local -r resource_types=("applications" "applicationsets" "appprojects")

    local rt
    for rt in "${resource_types[@]}"; do
        cleanup_resources "$rt" "$namespace"
    done

    log_info "Cleanup of ArgoCD CRs in namespace '$namespace' completed successfully."
}

# Ensures the script is not being sourced and executes the main function with all provided arguments.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
