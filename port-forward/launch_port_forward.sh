#!/usr/bin/env bash
set -eo pipefail
source "../lib/log.sh"
source "../lib/utils.sh"

usage() {
  echo "Usage: $(basename "$0") SERVICE_NAME [OPTIONS] [PORT_FORWARD_OPTIONS]"
  echo
  echo "Opens Port-Forward to specified service name. Service name relates to configuration in port-forward-config file."
  echo "Provides flag to open Port Forward in new terminal"
  echo
  echo "Options:"
  echo "  -l, --loop        Start port-forward in loop to recreate connection if it breaks"
  echo "  -b, --bg          Start port-forward as background process"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    service_name=""
    loop="true"
    bg="false"
    declare -a opts

    # Parse user input
    while [[ $# -gt 0 ]]; do
        case "$1" in
        --help | -h)
            usage
            exit 0
            ;;
        --loop | -l)
            loop="true"
            shift
            ;;
        --bg | -b)
            bg="true"
            shift
            ;;
        *)
            if [[ -z "$service_name" ]]; then
                service_name="$1"
                shift 1
            else
              break
            fi
            ;;
        esac
    done

    opts=("$@")

    # parameter validation
    if [[ -z "$service_name" ]]; then
        usage
        exit 2
    fi

    dir="$(dirname "$0")"
    config_file="$dir/port-forward-config"

    config_line="$(grep "${service_name}#" "$config_file" || true)"
    if [[ -z "$config_line" ]]; then
        log::error "No config found for service $service_name" >&2
        exit 1
    fi

    "$dir"/port_forward.sh "$service_name" "$loop" "$bg" "${opts[@]}"
fi
