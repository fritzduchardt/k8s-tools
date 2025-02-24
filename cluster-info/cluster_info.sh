#!/usr/bin/env bash

source "../lib/log.sh"
source "../lib/utils.sh"

NS="$(k8s::current_namespace)"
CONTEXT=$(k8s::current_context)
if [[ "$NS" != "none" || "$CONTEXT" != "none" ]]; then
  printf "%s // %s" "$NS" "$CONTEXT"
fi
