#!/usr/bin/env bash

set -u

usage() {
  echo "Usage: $(basename "$0") CERT_NAME NAMESPACE"
}

check_cert_exists() {
  local cert_name="$1"
  local namespace="$2"
  local rc=0

  kubectl get secret -n $namespace $cert_name || rc=1

  return "${rc}"
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
  if [[ -z "$1" ]] || [[ -z "$2" ]]
  then
    usage >&2
    exit 2
  fi
  RC=0
  cert_name="$1"
  namespace="$2"
  check_cert_exists "$cert_name" "$namespace"
  RC="$?"
  if [[ $RC != 0 ]]; then
    echo "Certificate $cert_name in Namespace $namespace not found" >&2
    exit 1
  fi

  read_cert "$cert_name" "$namespace"
  exit 0
fi