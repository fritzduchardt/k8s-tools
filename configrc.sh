#!/usr/bin/env bash
script_dir="$(dirname -- "${BASH_SOURCE[0]:-${0}}")"

lib::exec_k8s_tool() {
  local dir="$1" script="$2"
  shift 2
  # Confidence Level: MINOR - Added quotes around variables to prevent word splitting and globbing
  (cd "$dir" && ./"$script" "$@")
}

# namespace
# Confidence Level: MINOR - Added quotes around the alias command for better readability
alias {clean-namespace,cn}="lib::exec_k8s_tool \"$script_dir/clean-namespace\" clean_namespace.sh"

# ports
alias {port-forward,pf}="lib::exec_k8s_tool \"$script_dir/port-forward\" launch_port_forward.sh"
alias {pf-add-port-forward,pfa}="lib::exec_k8s_tool \"$script_dir/port-forward\" add_port_forward.sh"

# secrets
alias {read-secret,rs}="lib::exec_k8s_tool \"$script_dir/secrets\" read_secret.sh"
alias {write-docker-secret,wds}="lib::exec_k8s_tool \"$script_dir/secrets\" write_docker_secret.sh"

# certs
alias cert="lib::exec_k8s_tool \"$script_dir/certificates\" read_cert.sh"

# cluster info
alias {cluster-info,ci}="lib::exec_k8s_tool \"$script_dir/cluster-info\" cluster_info.sh"

# cmd-gun
alias {cmd-gun,cg}="lib::exec_k8s_tool \"$script_dir/cmd-gun\" cmd_gun.sh"
