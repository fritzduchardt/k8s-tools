#!/bin/bash

set -eo pipefail

SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"

usage() {
    echo """
Usage: $0 [OPTIONS] [NAMESPACE]

Select a Kubernetes namespace interactively or directly.

Arguments:
    NAMESPACE           Optional namespace to select directly

Options:
    -h, --help         Show this help message

Examples:
    $0                  # Interactive selection with fzf
    $0 default          # Select 'default' namespace directly
    $0 kube-system      # Select 'kube-system' namespace directly
"""
}

select_namespace_interactively() {
    local namespaces
    namespaces="$(k8s::get_all_namespaces)"

    if [[ -z "$namespaces" ]]; then
        log::error "No namespaces found"
        return 1
    fi

    local selected
    selected="$(echo "$namespaces" | fzf --height=40% --reverse --prompt="Select namespace: ")"

    if [[ -z "$selected" ]]; then
        log::info "No namespace selected"
        return 1
    fi

    echo "$selected"
}

select_namespace_directly() {
    local namespace="$1"
    local namespaces
    namespaces="$(k8s::get_all_namespaces)"

    if echo "$namespaces" | grep -q "^$namespace$"; then
        echo "$namespace"
    else
        log::error "Namespace '$namespace' not found"
        return 1
    fi
}

main() {
    local namespace=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            -*)
                log::error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                namespace="$1"
                shift
                ;;
        esac
    done

    local selected_namespace

    if [[ -n "$namespace" ]]; then
        selected_namespace="$(select_namespace_directly "$namespace")"
    else
        selected_namespace="$(select_namespace_interactively)"
    fi

    if [[ -n "$selected_namespace" ]]; then
        log::info "Selected namespace: $selected_namespace"
        lib::exec kubectl config set-context --current --namespace="$selected_namespace"
        log::info "Namespace switched to: $selected_namespace"
    else
        exit 1
    fi
}

main "$@"
