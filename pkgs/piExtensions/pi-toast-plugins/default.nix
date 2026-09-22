{ buildPiExtension }:

# The Toast Claude Code plugin marketplace, which ships a pi bridge extension
# (extensions/pi-toast-plugins) declared through package.json's `pi.extensions`,
# so pi loads it from the repository root and the bridge finds plugins/ beside it.
buildPiExtension {
  pname = "pi-toast-plugins";
  version = "2026-09-22";

  src = fetchGit {
    url = "git@github.toasttab.com:toasttab/claude-marketplace.git";
    rev = "d5ebc480009e277314fe0b6e399d98cc5373ddc4";
    ref = "main";
    narHash = "sha256-34jpiWhbdsXf0AucyxQj6bd4zpquzESeEQih86R5lSg=";
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
