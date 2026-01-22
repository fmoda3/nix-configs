#!/usr/bin/env nix-shell
#!nix-shell --pure --keep NIX_PATH -i bash --packages curl nix coreutils

set -euo pipefail

# Get latest version from the distribution endpoint
version=$(curl -s "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/latest")

echo "Latest version: $version"

# Base URL for downloads
base_url="https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases"

# Function to get SRI hash for a URL
get_sri_hash() {
    local url="$1"
    nix-prefetch-url --type sha256 "$url" 2>/dev/null | xargs nix hash convert --hash-algo sha256 --to sri
}

echo "Fetching hashes for version $version..."

# Get hashes for all platforms
echo "  Fetching aarch64-darwin hash..."
hash_aarch64_darwin=$(get_sri_hash "${base_url}/${version}/darwin-arm64/claude")

echo "  Fetching x86_64-darwin hash..."
hash_x86_64_darwin=$(get_sri_hash "${base_url}/${version}/darwin-x64/claude")

echo "  Fetching x86_64-linux hash..."
hash_x86_64_linux=$(get_sri_hash "${base_url}/${version}/linux-x64/claude")

echo "  Fetching aarch64-linux hash..."
hash_aarch64_linux=$(get_sri_hash "${base_url}/${version}/linux-arm64/claude")

# Path to the default.nix file
script_dir="$(dirname "$(readlink -f "$0")")"
default_nix="${script_dir}/default.nix"

echo "Updating ${default_nix}..."

# Update the version
sed -i "s/version = \"[^\"]*\"/version = \"${version}\"/" "$default_nix"

# Update the hashes using more specific patterns
sed -i "s|\"aarch64-darwin\" = {[^}]*os = \"darwin\";[^}]*arch = \"arm64\";[^}]*hash = \"[^\"]*\";|\"aarch64-darwin\" = {\n      os = \"darwin\";\n      arch = \"arm64\";\n      hash = \"${hash_aarch64_darwin}\";|g" "$default_nix"

sed -i "s|\"x86_64-darwin\" = {[^}]*os = \"darwin\";[^}]*arch = \"x64\";[^}]*hash = \"[^\"]*\";|\"x86_64-darwin\" = {\n      os = \"darwin\";\n      arch = \"x64\";\n      hash = \"${hash_x86_64_darwin}\";|g" "$default_nix"

sed -i "s|\"x86_64-linux\" = {[^}]*os = \"linux\";[^}]*arch = \"x64\";[^}]*hash = \"[^\"]*\";|\"x86_64-linux\" = {\n      os = \"linux\";\n      arch = \"x64\";\n      hash = \"${hash_x86_64_linux}\";|g" "$default_nix"

sed -i "s|\"aarch64-linux\" = {[^}]*os = \"linux\";[^}]*arch = \"arm64\";[^}]*hash = \"[^\"]*\";|\"aarch64-linux\" = {\n      os = \"linux\";\n      arch = \"arm64\";\n      hash = \"${hash_aarch64_linux}\";|g" "$default_nix"

echo "Updated to version ${version}"
echo "  aarch64-darwin: ${hash_aarch64_darwin}"
echo "  x86_64-darwin:  ${hash_x86_64_darwin}"
echo "  x86_64-linux:   ${hash_x86_64_linux}"
echo "  aarch64-linux:  ${hash_aarch64_linux}"

# Also update the VS Code extension if needed
nix-update vscode-extensions.anthropic.claude-code --use-update-script --version "$version" 2>/dev/null || echo "Note: Could not update VS Code extension (this is optional)"
