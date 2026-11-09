#!/usr/bin/env bash
# Usage: tests/vm.sh up|down [image]  (Tart macOS VM for integration tests)
set -euo pipefail

name=macos-test
default_image=ghcr.io/cirruslabs/macos-tahoe-base:latest
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
inv="$root/tests/inventory/vm.yml"

case "${1:-}" in
  up)
    image="${2:-$default_image}"
    tart list --quiet | grep -qx "$name" || tart clone "$image" "$name"
    nohup tart run --no-graphics "$name" >/dev/null 2>&1 &
    ip="$(tart ip --wait 120 "$name")"
    cat >"$inv" <<EOF
---
all:
  hosts:
    $name:
      ansible_host: $ip
      ansible_user: admin
      ansible_password: admin
      ansible_ssh_common_args: -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
EOF
    echo "VM $name up at $ip"
    ;;
  down)
    tart stop "$name" || true
    tart delete "$name" || true
    ;;
  *)
    echo "Usage: $0 up|down [image]" >&2
    exit 2
    ;;
esac
