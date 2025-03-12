#!/usr/bin/env bash

shopt -s globstar # enable globbing

source "../lib/log.sh"
source "../lib/utils.sh"

help() {
    log::info """
Deletes all resources within a namespace without deleting namespace itself

Usage:
    $0 NAMESPACE_NAME

    Arguments:
    NAMESPACE_NAME                  Name of namespace to clean out.

    Options:
        -h, --help                  Show this help message
        -D, --debug                 Enable debug logging
        -T, --trace                 Enable trace logging
        -d, --dry-run               Execute in dry-run. Just show commands, don't execute them.
"""
}

namespace_exists() {
    local ns="$1"
    # Confidence Level: MINOR - Simplified command and eliminated unnecessary redirection
    lib::exec kubectl get ns "$ns" >/dev/null
}

clean_namespace() {
    local ns="$1"
    local -a args
    args=("--all" "--wait=true" "-n" "$ns" )
    # Removing workloads before everything else to free up pvcs
    log::info "Removing all workloads"
    lib::exec kubectl delete statefulsets "${args[@]}"
    lib::exec kubectl delete deployments "${args[@]}"
    lib::exec kubectl delete replicasets "${args[@]}"
    lib::exec kubectl delete daemonsets "${args[@]}"
    lib::exec kubectl delete pods "${args[@]}"
    lib::exec kubectl delete pvc "${args[@]}"
    lib::exec kubectl delete roles "${args[@]}"
    log::info "Removing everything else"
    lib::exec kubectl delete all "${args[@]}"
}

main() {
    local namespace

    # Parse user input
    while [[ $# -gt 0 ]]; do
        case "$1" in
        --help | -h)
            help
            exit 0
            ;;
        --debug | -D)
            LOG_LEVEL=debug
            shift 1
            ;;
        --trace | -T)
            LOG_LEVEL=trace
            shift 1
            ;;
        --dry-run | -d)
            DRY_RUN=true
            shift 1
            ;;
        *)
            if [[ -z "$namespace" ]]; then
                namespace="$1"
                shift 1
            fi
            ;;
        esac
    done

    # Validate
    if [[ -z "$namespace" ]]; then
        log::error "You must specify a namespace to clean out"
        help >&2
        exit 2
    fi

    if ! namespace_exists "$namespace"; then
        log::error "Namespace $namespace does not exist"
        exit 2
    fi

    log::info "Ready to clean namespace \"$namespace\"."
    lib::prompt "Go ahead?"

    clean_namespace "$namespace"

    log::info "Successfully cleaned namespace: $namespace"
}

main "$@"
