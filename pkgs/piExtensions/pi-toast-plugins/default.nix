{ buildPiExtension }:

# The Toast Claude Code plugin marketplace, which ships a pi bridge extension
# (extensions/pi-toast-plugins) declared through package.json's `pi.extensions`,
# so pi loads it from the repository root and the bridge finds plugins/ beside it.
buildPiExtension {
  pname = "pi-toast-plugins";
  version = "2026-09-16";

  src = fetchGit {
    url = "git@github.toasttab.com:toasttab/claude-marketplace.git";
    rev = "a0985798b58018b04dc6c2452a81c8d4e871cf23";
    ref = "main";
    narHash = "sha256-SWbO2yAsHn2M96shJxsm7Rz7hBSXgNIIgN0zKRosV2s=";
  };

  prunePaths = [
    ".github"
    "benchmarks"
    "docs"
    "plans"
    "research"
    "smoketest"
    "extensions/pi-toast-plugins/tests"
  ];
}
