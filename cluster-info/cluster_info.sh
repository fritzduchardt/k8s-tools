#!/usr/bin/env bash

source "../lib/log.sh"
source "../lib/utils.sh"

printf "%s // %s" "$(k8s::current_namespace)" "$(k8s::current_context)"
