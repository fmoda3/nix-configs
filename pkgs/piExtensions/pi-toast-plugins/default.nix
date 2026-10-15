{ buildPiExtension }:

# The Toast Claude Code plugin marketplace, which ships a pi bridge extension
# (extensions/pi-toast-plugins) declared through package.json's `pi.extensions`,
# so pi loads it from the repository root and the bridge finds plugins/ beside it.
buildPiExtension {
  pname = "pi-toast-plugins";
  version = "2026-10-13";

  src = fetchGit {
    url = "git@github.toasttab.com:toasttab/claude-marketplace.git";
    rev = "53437f1de12abf2edc58ad3dd0a9c9361f288742";
    ref = "main";
    narHash = "sha256-QurSsrixNjKljbN4bnNgwULlccl53ARxhGi6k8Kp+TM=";
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
