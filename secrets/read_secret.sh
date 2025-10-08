#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(dirname -- "$0")"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../lib/utils.sh"

usage() {
  echo "Usage: $(basename "$0") SECRET_NAME NAMESPACE_NAME FIELD_NAME"
  echo
  echo "Reads field from secret and base64 decodes it."
}

check_prerequisites() {
  local rc=0
  if ! command -v kubectl >/dev/null; then
      log::error "required command kubectl not found!"
      rc=1
  fi
  if ! command -v base64 >/dev/null; then
      log::error "required command base64 not found!"
      rc=1
  fi
  return "$rc"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # parameter validation
  if [[ "$#" -ne 2 ]]; then
    usage >&2
    exit 2
  fi

  # prerequisite validation
  check_prerequisites || { log::error "prerequisites not met"; exit 1; }

  secret="$1"
  field="$2"
  namespace="$3"

  if [[ -z "$namespace" ]]; then
    namespace="$(k8s::current_namespace)"
  fi

  lib::exec kubectl get secret -n "$namespace" "$secret" -o jsonpath="{.data.$field}" | base64 -d
fi
