#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"

usage() {
    cat <<EOF
Usage: "$0" [-n NAMESPACE]

Removes finalizers and then deletes ArgoCD Custom Resources (Applications,
ApplicationSets, and AppProjects) from the specified Kubernetes namespace.

This is a destructive operation that should be used with caution, for example,
when a namespace is stuck in a terminating state due to ArgoCD finalizers.

OPTIONS:
  -n NAMESPACE   The Kubernetes namespace to clean up. If not provided, the current namespace will be used.
  -h, --help     Display this help message and exit.
EOF
    exit 1
}

# Removes finalizers and deletes all instances of a given resource type in a namespace.
cleanup_resources() {
    local resource_type="$1"
    local namespace="$2"

    log::info "--- Processing resource type: \"$resource_type\" in namespace '$namespace' ---"

    # Get resource names. If the command returns no names, the loop won't execute.
    local resources
    resources=$("$KUBECTL_BIN" get "$resource_type" -n "$namespace" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || true)

    if [[ -z "$resources" ]]; then
        log::info "No '$resource_type' resources found in namespace '$namespace'."
        return
    fi

    local name
    for name in $resources; do
        log::info "Processing \"$resource_type\" '$name'..."

        log::info "  -> Removing finalizer..."
        if ! "$KUBECTL_BIN" patch "$resource_type" "$name" -n "$namespace" --type='json' -p='[{"op": "remove", "path": "/metadata/finalizers"}]' &>/dev/null; then
            log::warn "     Could not remove finalizer from \"$resource_type\" '$name'. It might not have one or was already deleted."
        fi

        log::info "  -> Deleting resource..."
        "$KUBECTL_BIN" delete "$resource_type" "$name" -n "$namespace" --ignore-not-found=true
    done

    log::info "--- Finished processing resource type: \"$resource_type\" ---"
}

verify_namespace() {
    local namespace="$1"

    if ! "$KUBECTL_BIN" get namespace "$namespace" &>/dev/null; then
        log::error "Namespace '$namespace' does not exist"
        exit 1
    fi
}

main() {
    local namespace=""

    # Parse command line options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n)
                namespace="$2"
                shift 2
                ;;
            -h|--help)
                usage
                ;;
            *)
                log::error "Unknown option: $1"
                usage
                ;;
        esac
    done

    if [[ -z "$namespace" ]]; then
        if ! namespace="$(k8s::current_namespace)"; then
          exit 1
        fi
        log::info "No namespace provided, using current namespace: '$namespace'"
    fi

    log::info "Starting ArgoCD CR cleanup in namespace: '$namespace'"

    verify_namespace "$namespace"

    # Define the ArgoCD resource types to be processed
    local -r resource_types=("applications.argoproj.io" "applicationsets.argoproj.io" "appprojects.argoproj.io")

    local rt
    for rt in "${resource_types[@]}"; do
        cleanup_resources "$rt" "$namespace"
    done

    log::info "Cleanup of ArgoCD CRs in namespace '$namespace' completed successfully."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
