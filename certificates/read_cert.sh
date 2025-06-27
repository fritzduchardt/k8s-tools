#!/usr/bin/env bash
source "../lib/log.sh"
source "../lib/utils.sh"

usage() {
  echo "Usage: $(basename "$0") ACTION (read/extract) CERT_NAME NAMESPACE" >&2
}

check_prerequisites() {
  local rc=0
  if ! command -v kubectl >/dev/null; then
    log::error "required command kubectl not found!" >&2
    rc=1
  fi
  if ! command -v openssl >/dev/null; then
    log::error "required command openssl not found!" >&2
    rc=1
  fi
  if ! command -v base64 >/dev/null; then
    log::error "required command base64 not found!" >&2
    rc=1
  fi
  return "$rc"
}

check_cert_exists() {
  local cert_name="$1"
  local namespace="$2"
  cert="$(lib::exec kubectl get secret --field-selector type=kubernetes.io/tls --field-selector metadata.name="$cert_name" -n "$namespace")"
  if [[ -n "$cert" ]]; then
    return 0
  fi
  return 1
}

read_cert() {
  lib::exec openssl x509 --noout -text <<<"$(lib::exec kubectl get secret -n "$namespace" "$cert_name" -o go-template='{{ index .data "tls.crt" | base64decode }}')"
}

extract_cert() {
  lib::exec kubectl get secret -n "$namespace" "$cert_name" -o go-template='{{ index .data "tls.crt" | base64decode }}' >"$cert_name.crt"
  lib::exec kubectl get secret -n "$namespace" "$cert_name" -o go-template='{{ index .data "tls.key" | base64decode }}' >"$cert_name.key"
  log::info "Certificate and key extracted to $cert_name.crt and $cert_name.key"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # parameter validation
  if [[ -z "$1" ]] || [[ -z "$2" ]]; then
    usage >&2
    exit 2
  fi

  check_prerequisites
  if ! check_prerequisites; then
    log::error "prerequisites not met"
    exit 1
  fi

  cmd="$1"
  cert_name="$2"
  namespace="$3"

  if [[ -z "$namespace" ]]; then
    namespace="$(k8s::current_namespace)"
  fi

  if ! check_cert_exists "$cert_name" "$namespace"; then
    log::error "No TLS certificate with name $cert_name was found in namespace $namespace"
    exit 1
  fi


  log::info "Cert found: $cert_name"

  case "$cmd" in
  "read")
    if ! read_cert "$cert_name" "$namespace"; then
      log::error "Failed to read certificate $cert_name in namespace $namespace"
      exit 1
    fi
    ;;
  "extract")
    if ! extract_cert "$cert_name" "$namespace"; then
      log::error "Failed to extract certificate $cert_name in namespace $namespace"
      exit 1
    fi
    ;;
  *)
    usage >&2
    exit 2
    ;;
  esac
fi
