#!/usr/bin/env bash

set -eo pipefail

SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"


# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    log::error "kubectl not found. Please install kubectl first."
    exit 1
fi

# Check if fzf is available
if ! command -v fzf &> /dev/null; then
    log::error "fzf not found. Please install fzf first."
    exit 1
fi

# Function to recursively get kubectl explain output
get_recursive_explain() {
    local resource="$1"
    if [[ $# -eq 0 ]]; then
      resource="$(kubectl api-resources -oname | fzf)"
    fi
    local -r tempfile="$(mktemp)"
    log::info "Retrieving spec.."
    lib::exec kubectl explain "$resource.spec" --recursive >"$tempfile" || {
        log::error "Failed to get kubectl explain output for $resource"
        return 1
    }

    fzf --height 80% \
        --border \
        --prompt "$resource.spec > " \
        --preview "grep -A 100 {} $tempfile" \
        --preview-window=right:60%:wrap \
        <"$tempfile" >/dev/null
}

# Main execution
if ! get_recursive_explain "$@"; then
  log::error "Failed to get kubectl explain output"
fi
