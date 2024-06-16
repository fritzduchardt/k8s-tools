#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/log.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/utils.sh"

usage() {
  echo "Usage: $(basename "$0") [SECRET_NAME] [OPTIONS]"
  echo
  echo "Writes a docker secret to a kubernetes cluster"
  echo
  echo "Arguments:"
  echo "   SECRET_NAME        Name of the secret. Defaults to github-pull-secret"
  echo "Options:"
  echo "   -e, --email        Email. Defaults to fritz@duchardt.net"
  echo "   -n, --namespace    Namespace of the secret. Defaults to current namespace"
  echo "   -p, --password     Docker User. Defaults to prompt"
  echo "   -s, --server       Docker Server. Defaults to Github"
  echo "   -u, --user         Docker User. Defaults to none"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
  email="fritz@duchardt.net"
  namespace=""
  password=""
  secret_name="github-pull-secret"
  server="ghcr.io/fritzduchardt"
  user="none"

  while [[ $# -gt 0 ]]; do
    case "$1" in
    --help | -h)
      usage
      ;;
    --debug | -D)
      # shellcheck disable=SC2034
      LOG_LEVEL="debug"
      shift 1
      ;;
    --trace | -T)
      # shellcheck disable=SC2034
      LOG_LEVEL="trace"
      shift 1
      ;;
    --dry-run)
      DRY_RUN="true"
      shift 1
      ;;
    --namespace | -n)
      namespace="$2"
      shift 2
      ;;
    --user | -u)
      user="$2"
      shift 2
      ;;
    --server | -s)
      server="$2"
      shift 2
      ;;
    --password | -p)
      password="$2"
      shift 2
      ;;
    --user | -i)
      user="$2"
      shift 2
      ;;
    --email | -e)
      email="$2"
      shift 2
      ;;
    *)
      if [[ -z "$secret_name" ]]; then
        secret_name="$1"
        shift 1
      else
        log::error "Unknown argument: $1"
        shift 1
      fi
      ;;
    esac
  done

  if [ -z "$namespace" ]; then
    k8s::select_namespace
  fi

  if [[ -z "$password" ]]; then
    read -p "Enter password / token: " password
  fi

  if k8s::resource_exists secret "$secret_name" "$namespace"; then
    log::info "Secret $secret_name already exists in namespace $namespace"
    read -p "Do you want to overwrite it? [y/N] " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      log::info "Aborting"
      exit 0
    fi
    if ! lib::exec kubectl delete secret "$secret_name" -n "$namespace"; then
      log::error "Failed to delete secret"
      exit 1
    fi
  fi

  if ! lib::exec kubectl create secret docker-registry "$secret_name" --namespace "$namespace" --docker-server="$server" --docker-username="$user" --docker-password="$password" --docker-email="$email"; then
    log::error "Failed to create secret"
    exit 1
  fi
  log::info "Success"
fi
