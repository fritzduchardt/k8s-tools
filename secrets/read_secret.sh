#!/usr/bin/env bash
set -euo pipefail
source "../lib/log.sh"
source "../lib/utils.sh"

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
  if [[ "$#" -ne 3 ]]; then
    usage >&2
    exit 2
  fi

  # prerequisite validation
  check_prerequisites || { log::error "prerequisites not met"; exit 1; }

  secret="$1"
  namespace="$2"
  field="$3"

  lib::exec kubectl get secret -n "$namespace" "$secret" -o go-template='{{ index ".data" "'"${field}"'" | base64 -d }}'
fi
