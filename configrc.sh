#!/usr/bin/env bash
k8s_tools_scripts_dir="$(dirname "$0")"

# namespace
exec_clean_namespace() { (cd "$k8s_tools_scripts_dir"/clean-namespace && ./clean_namespace.sh "$@") }
alias {clean-namespace,cn}="exec_clean_namespace"

# ports
exec_port_forward() { (cd "$k8s_tools_scripts_dir"/port-forward && ./launch_port_forward.sh "$@") }
alias {port-forward,pf}="exec_port_forward"
exec_add_port_forward() { (cd "$k8s_tools_scripts_dir"/port-forward && ./add_port_forward.sh "$@") }
alias {add-port-forward,ap}="exec_add_port_forward"

# secrets
exec_read_secret() { (cd "$k8s_tools_scripts_dir"/secrets && ./read_secret.sh "$@") }
alias {read-secret,rs}="exec_read_secret"
exec_write_docker_secret() { (cd "$k8s_tools_scripts_dir"/secrets && ./write_docker_secret.sh "$@") }
alias {write-docker-secret,wds}="exec_write_docker_secret"

# certs
exec_read_cert() { (cd "$k8s_tools_scripts_dir"/read-cert && ./read_cert.sh "$@") }
alias cert="exec_read_cert"
alias {cluster-info,ci}="(cd $k8s_tools_scripts_dir/cluster-info && ./cluster_info.sh)"
