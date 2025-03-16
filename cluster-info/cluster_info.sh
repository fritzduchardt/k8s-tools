#!/usr/bin/env bash

source "../lib/log.sh"
source "../lib/utils.sh"

NS="$(k8s::current_namespace)"
NS="${NS:-none}"
CONTEXT=$(k8s::current_context)
if [[ -n "$NS" || -n "$CONTEXT" ]]; then
  printf "%s // %s" "$NS" "$CONTEXT"
fi
