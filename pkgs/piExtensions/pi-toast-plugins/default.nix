{ buildPiExtension }:

# The Toast Claude Code plugin marketplace, which ships a pi bridge extension
# (extensions/pi-toast-plugins) declared through package.json's `pi.extensions`,
# so pi loads it from the repository root and the bridge finds plugins/ beside it.
buildPiExtension {
  pname = "pi-toast-plugins";
  version = "2026-10-08";

  src = fetchGit {
    url = "git@github.toasttab.com:toasttab/claude-marketplace.git";
    rev = "985fa5b653b66aa5f7700a9c51a531a04f5431c0";
    ref = "main";
    narHash = "sha256-ZHmPBLyFDlCd0Z6H4Fi+o4Cl2zdOo97/TcN2UD4vJDQ=";
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
