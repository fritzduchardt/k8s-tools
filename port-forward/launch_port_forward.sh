#!/usr/bin/env bash
set -euo pipefail

service=${1:?Please provide service}
cluster=$(kubectl config current-context)

gnome-terminal --title "$KUBE_CLUSTER - ${cluster^} - ${service^}" -- $(dirname "$0")/port_forward.sh "$service" "$KUBECONFIG"