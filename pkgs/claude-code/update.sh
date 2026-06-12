#!/usr/bin/env nix
#!nix shell --ignore-environment .#cacert .#curl .#bash --command bash

set -euo pipefail

BASE_URL="https://downloads.claude.ai/claude-code-releases"

VERSION=$(curl -fsSL "$BASE_URL/latest")

curl -fsSL "$BASE_URL/$VERSION/manifest.json" --output pkgs/claude-code/manifest.json