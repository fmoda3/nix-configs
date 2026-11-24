{ buildPiExtension }:

# The Toast Claude Code plugin marketplace, which ships a pi bridge extension
# (extensions/pi-toast-plugins) declared through package.json's `pi.extensions`,
# so pi loads it from the repository root and the bridge finds plugins/ beside it.
buildPiExtension {
  pname = "pi-toast-plugins";
  version = "2026-11-24";

  src = fetchGit {
    url = "ssh://git@github.toasttab.com/toasttab/claude-marketplace.git";
    rev = "89910f9bba575debb39fc88f55db7970f35e72aa";
    ref = "main";
    narHash = "sha256-64I6N7lzmqM9a8/Goe2j819yDqSR1xWZkMX6NNUxAtI=";
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
