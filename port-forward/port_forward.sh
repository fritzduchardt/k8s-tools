#!/usr/bin/env bash

set -euo pipefail

service=${1:-argocd}
kubeconfig=${2:?Please provide KUBECONFIG}
target_port=80
local_port=9292
path=svc/oncite-rollout-server
namespace=oncite-rollout

export KUBECONFIG=$kubeconfig

case $service in
argocd)
  target_port=80
  local_port=9292
  ;;
grafana)
  target_port=80
  local_port=3000
  namespace=gec-monitoring
  path=svc/gec-monitoring-grafana
esac

while true; do
  echo "Starting Port Forwarding to Service: $path within Namespace: $namespace and Port-Mapping: $local_port:$target_port"
  kubectl port-forward $path -n $namespace $local_port:$target_port
done