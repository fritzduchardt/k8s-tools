#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

# shellcheck source=./../lib/log.sh
source "$SCRIPT_DIR/../lib/log.sh"
# shellcheck source=./../lib/utils.sh
source "$SCRIPT_DIR/../lib/utils.sh"

usage() {
  cat >&2 <<EOF

Usage: ./$(basename "${BASH_SOURCE[0]}") [OPTIONS] SECRET_NAME

Writes a docker secret to a kubernetes cluster leveraging config files for reoccurring settings like secret name,
email, server, and user.

Arguments:
   SECRET_NAME        Name of the secret. Defaults to github-pull-secret

Options:
   -e, --email        Defaults to fritz@duchardt.net
   -n, --namespace    Namespace of the secret. Defaults to current namespace
   -p, --password     Docker User. Defaults to prompt
   -s, --server       Docker Server. Defaults to GitHub
   -u, --user         Docker User. Defaults to none

Examples:

  # Create a secret leveraging all config files
  ./$(basename "${BASH_SOURCE[0]}")

  # Create a secret with a custom name
  ./$(basename "${BASH_SOURCE[0]}") my-secret

  # Create a secret with a custom name and namespace
  ./$(basename "${BASH_SOURCE[0]}") -n my-namespace my-secret

  # Create a secret with a custom name, namespace, and email
  ./$(basename "${BASH_SOURCE[0]}") -n my-namespace -e my@email.com

  # Create a secret with a custom name, namespace, email, and server
  ./$(basename "${BASH_SOURCE[0]}") -n my-namespace -e my@email.com -s my-server

  # Create a secret with a custom name, namespace, email, server, and user
  ./$(basename "${BASH_SOURCE[0]}") -n my-namespace -e my@email.com -s my-server -u my-user

EOF
  exit 2
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  email=""
  namespace=""
  secret_name=""
  server=""
  user="none"

  while [[ $# -gt 0 ]]; do
    case "$1" in
    --help | -h)
      usage
      ;;
    --debug | -D)
      LOG_LEVEL="debug"
      shift 1
      ;;
    --trace | -T)
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

  if [[ -z "$secret_name" ]]; then
    secret_name="$(fzf::select_from_config "$SCRIPT_DIR/config/names.txt" "Select a name for the secret")"
  fi

  if [ -z "$namespace" ]; then
    namespace="$(k8s::select_namespace)"
  fi

  if [[ -z "$email" ]]; then
    email="$(fzf::select_from_config "$SCRIPT_DIR/config/emails.txt" "Select an email for the secret")"
  fi

  if [[ -z "$server" ]]; then
    server="$(fzf::select_from_config "$SCRIPT_DIR/config/servers.txt" "Select a server url for the secret")"
  fi

  read -rp "Enter password: " password

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
