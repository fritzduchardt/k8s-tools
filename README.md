# k8s-tools

A collection of shell scripts designed to simplify common and advanced Kubernetes operations.

## Overview

This repository provides a toolkit for DevOps engineers and Kubernetes administrators to streamline daily tasks, troubleshoot issues, and manage cluster resources more efficiently. The scripts leverage common command-line tools like `kubectl`, `fzf`, and `openssl` to provide powerful, interactive, and automated functionality.

## Features

- **Namespace Management**:
  - Cleanly delete all resources within a namespace without deleting the namespace itself.
  - Execute commands across multiple namespaces that match a specific prefix.

- **Resource Troubleshooting & Management**:
  - Forcefully remove ArgoCD custom resources (Applications, ApplicationSets, AppProjects) to unblock terminating namespaces.
  - Remove finalizers from any Kubernetes resource to resolve deletion-related issues.
  - Interactively explore Kubernetes resource specifications using `kubectl explain`.

- **Secrets & Certificates**:
  - Interactively create or update `docker-registry` secrets using pre-configured or user-provided values.
  - Read and decode data from any Kubernetes secret.
  - Read or extract TLS certificates and keys from `kubernetes.io/tls` secrets.

- **Connectivity**:
  - A simplified system for managing and launching `kubectl port-forward` sessions using predefined shortcuts.

- **Convenience**:
  - Quickly display the current Kubernetes context and namespace.
  - A central `configrc.sh` file provides convenient shell aliases for all scripts in the toolkit.

## Usage

Each script can be executed directly from its directory. For the best experience, source the `configrc.sh` file in your shell's configuration file (e.g., `~/.bashrc`, `~/.zshrc`) to make all tools available as simple aliases.

```bash
# Add this to your ~/.bashrc or ~/.zshrc
source /path/to/k8s-tools/configrc.sh
```
