#!/usr/bin/env bash

current_dir=$(dirname "$0")
# aliases
alias {port-forward,pf}="$current_dir"/port-forward/launch_port_forward.sh
alias {add-port-forward,ap}="$current_dir"/port-forward/add_port_forward.sh
alias {switch-config,sc}=". $current_dir"/switch-config/switch_config.sh
alias {add-config,ac}="$current_dir"/switch-config/add_config.sh
alias {remove-config,rc}="$current_dir"/switch-config/remove_config.sh
alias {read-secret,rs}="$current_dir"/secrets/read_secret.sh
alias {write-docker-secret,wds}="$current_dir"/secrets/write_docker_secret.sh
alias cert="$current_dir"/read-cert/read_cert.sh
alias {cluster-info,ci}="$current_dir"/cluster-info/cluster-info.sh
