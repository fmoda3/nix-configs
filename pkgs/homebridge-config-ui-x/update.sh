#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq gnugrep gnused git nix
# shellcheck shell=bash
set -euo pipefail

root="$(pwd)"
cd "$(readlink -e "$(dirname "${BASH_SOURCE[0]}")")"

# Detect flake vs nixpkgs context and set the package expression accordingly
if [ -f "$root/flake.nix" ]; then
  system=$(nix eval --raw --impure --expr builtins.currentSystem)
  pkg="(builtins.getFlake \"$root\").legacyPackages.$system.homebridge-config-ui-x"
  nix_file="default.nix"
else
  pkg="(import $root/default.nix {}).homebridge-config-ui-x"
  nix_file="package.nix"
fi

nix_eval() {
  nix eval --json --impure --expr "$pkg.$1" | jq -r
}

# Build a fixed-output derivation with an empty hash to get the correct one
nix_prefetch() {
  local attr="$1"
  local expr="let src = $pkg.$attr; in (src.overrideAttrs or (f: src // f src)) (_: { outputHash = \"\"; outputHashAlgo = \"sha256\"; })"
  nix-build --impure --no-out-link --expr "$expr" 2>&1 | tr -s ' ' | grep -oP 'got:\s+\K\S+' || true
}

update_src_hash() {
  echo "Updating source hash..."
  local old_hash new_hash
  old_hash=$(nix_eval "src.outputHash")
  new_hash=$(nix_prefetch "src")
  if [ -z "$new_hash" ]; then
    echo "ERROR: Failed to determine new source hash"
    exit 1
  fi
  sed -i "s|$old_hash|$new_hash|g" "$nix_file"
}

update_npm_deps_hash() {
  echo "Updating npm dependencies hash..."
  local old_hash new_hash
  old_hash=$(nix_eval "npmDeps.outputHash")
  new_hash=$(nix_prefetch "npmDeps")
  if [ -z "$new_hash" ]; then
    echo "ERROR: Failed to determine new npm deps hash"
    exit 1
  fi
  sed -i "s|$old_hash|$new_hash|g" "$nix_file"
}

update_npm_deps_ui_hash() {
  echo "Updating ui npm dependencies hash..."
  local old_hash new_hash
  old_hash=$(nix_eval "npmDeps_ui.outputHash")
  new_hash=$(nix_prefetch "npmDeps_ui")
  if [ -z "$new_hash" ]; then
    echo "ERROR: Failed to determine new npm deps ui hash"
    exit 1
  fi
  sed -i "s|$old_hash|$new_hash|g" "$nix_file"
}

LATEST_VERSION=$(curl -fsSL "https://api.github.com/repos/homebridge/homebridge-config-ui-x/releases/latest" \
  | jq -r '.tag_name' \
  | sed 's/^v//')

CURRENT_VERSION=$(nix_eval "version")

if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
  echo "homebridge-config-ui-x is already up to date at version $CURRENT_VERSION"
  exit 0
fi

echo "Updating homebridge-config-ui-x from $CURRENT_VERSION to $LATEST_VERSION"

sed -i "s/version = \"$CURRENT_VERSION\"/version = \"$LATEST_VERSION\"/" "$nix_file"

update_src_hash
update_npm_deps_hash
update_npm_deps_ui_hash

echo "Successfully updated homebridge-config-ui-x from $CURRENT_VERSION to $LATEST_VERSION"
