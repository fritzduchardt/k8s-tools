#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $(basename "$0") SECRET_NAME NAMESPACE_NAME FIELD_NAME"
  echo
  echo "Reads field from secret and base64 decodes it."
}

check_prerequisites() {
  local rc=0
  if ! command -v kubectl >/dev/null
  then
      echo "required command kubectl not found!" >&2
      rc=1
  fi
  if ! command -v base64 >/dev/null
  then
      echo "required command base64 not found!" >&2
      rc=1
  fi
  return "$rc"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then

  # parameter validation
  if [[ "$#" -ne 3 ]]
  then
    usage >&2
    exit 2
  fi

  # prerequisite validation
  RC=0
  check_prerequisites
  RC="$?"
  if [[ $RC != 0 ]]
  then
    echo "prerequisites not met"
    exit 1
  fi

  secret="$1"
  namespace="$2"
  field=$(sed 's#\.#\\.#g' <<<"$3")

  kubectl get secret -n "$namespace" "$secret" -o jsonpath="{.data.$field}" | base64 -d
fi