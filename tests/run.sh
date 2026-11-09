#!/usr/bin/env bash
# Usage: tests/run.sh <role> [scenario] [--inventory localhost|vm]
set -euo pipefail

usage() {
  echo "Usage: $0 <role> [scenario] [--inventory localhost|vm]" >&2
  exit 2
}

positional=()
inventory=localhost
while [[ $# -gt 0 ]]; do
  case "$1" in
    --inventory) [[ $# -ge 2 ]] || usage; inventory="$2"; shift 2 ;;
    -*) usage ;;
    *) positional+=("$1"); shift ;;
  esac
done
[[ ${#positional[@]} -ge 1 && ${#positional[@]} -le 2 ]] || usage
role="${positional[0]}"
scenario="${positional[1]:-default}"

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dir="$root/tests/integration/$role/$scenario"
inv="$root/tests/inventory/$inventory.yml"
[[ -f "$dir/converge.yml" && -f "$dir/verify.yml" ]] || { echo "No scenario: $dir" >&2; exit 2; }
if [[ ! -f "$inv" ]]; then
  [[ "$inventory" == vm ]] && echo "No $inv: run tests/vm.sh up first" >&2 || echo "No inventory: $inv" >&2
  exit 2
fi

work="$(mktemp -d "${TMPDIR:-/tmp}/macos-tests.XXXXXX")"
trap 'rm -rf "$work"' EXIT

# The repo dir name differs from the collection name, so expose it under the FQCN.
mkdir -p "$work/collections/ansible_collections/finemas"
ln -s "$root" "$work/collections/ansible_collections/finemas/macos"
export ANSIBLE_COLLECTIONS_PATH="$work/collections${ANSIBLE_COLLECTIONS_PATH:+:$ANSIBLE_COLLECTIONS_PATH}:${ANSIBLE_HOME:-$HOME/.ansible}/collections"
export ANSIBLE_FORCE_COLOR=0
export ANSIBLE_NOCOLOR=1

run() {
  ansible-playbook -i "$inv" "$1" 2>&1 | tee "$2"
}

echo "== converge (1/2) =="
run "$dir/converge.yml" "$work/first.log"
echo "== converge (2/2, idempotence) =="
run "$dir/converge.yml" "$work/second.log"

recap="$(grep -E '^[^ ]+ +: ok=' "$work/second.log" || true)"
if [[ -z "$recap" ]] || grep -Eq 'changed=[1-9]|failed=[1-9]|unreachable=[1-9]' <<<"$recap"; then
  echo "Idempotence failed: second converge reported changes" >&2
  echo "$recap" >&2
  exit 1
fi

echo "== verify =="
run "$dir/verify.yml" "$work/verify.log"
echo "OK: $role/$scenario"
