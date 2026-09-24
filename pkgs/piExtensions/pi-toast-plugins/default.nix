{ buildPiExtension }:

# The Toast Claude Code plugin marketplace, which ships a pi bridge extension
# (extensions/pi-toast-plugins) declared through package.json's `pi.extensions`,
# so pi loads it from the repository root and the bridge finds plugins/ beside it.
buildPiExtension {
  pname = "pi-toast-plugins";
  version = "2026-09-23";

  src = fetchGit {
    url = "git@github.toasttab.com:toasttab/claude-marketplace.git";
    rev = "ac2fb44f58dba1f54aa917265bdd9646a86568d1";
    ref = "main";
    narHash = "sha256-yP36w3bIAiALWt4/oX/iuicuYb+rSX7F/oS/rGiN0WA=";
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
