#!/usr/bin/env bash

set -u

usage() {
  echo "Usage: $(basename "$0") CERT_NAME NAMESPACE"
  echo
  echo "Reads TLS Certificate straight from cluster and decodes it with openssl for perusal of cert details."
}

check_prerequisites() {
  local rc=0
  if ! command -v kubectl >/dev/null
  then
      echo "required command kubectl not found!" >&2
      rc=1
  fi
  if ! command -v openssl >/dev/null
  then
      echo "required command openssl not found!" >&2
      rc=1
  fi
  if ! command -v base64 >/dev/null
  then
      echo "required command base64 not found!" >&2
      rc=1
  fi
  return "$rc"
}

check_cert_exists() {
  local cert_name="$1"
  local namespace="$2"
  kubectl get secret --field-selector type=kubernetes.io/tls --field-selector metadata.name="$cert_name" -n "$namespace" 2> /dev/null | grep "$cert_name"
  return "$?"
}

read_cert() {
  local cert_name="$1"
  local namespace="$2"

  cert=$(kubectl get secret -n "$namespace" "$cert_name" -o jsonpath="{.data.tls\.crt}")
  cert_decoded=$(echo "$cert" | base64 -d)
  openssl x509 --noout -text <<<"$cert_decoded"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
  # parameter validation
  if [[ -z "$1" ]] || [[ -z "$2" ]]
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

  # main program
  cert_name="$1"
  namespace="$2"
  check_cert_exists "$cert_name" "$namespace"
  RC="$?"
  if [[ $RC != 0 ]]
  then
    echo "No TLS certificate with name $cert_name was found in namespace $namespace" >&2
    exit 1
  fi

  read_cert "$cert_name" "$namespace"
  exit 0
fi