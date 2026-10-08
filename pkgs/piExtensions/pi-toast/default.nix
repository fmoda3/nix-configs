{ buildPiExtension }:

buildPiExtension {
  pname = "pi-toast";
  version = "2026-10-08";

  src = fetchGit {
    url = "git@github.toasttab.com:toasttab/pi-toast.git";
    rev = "3ae8c34a5637a600f0654177864600202605fc20";
    ref = "main";
    narHash = "sha256-e1VQHCoid0I+QI4iIMFmqIpD4IkLQtFVJLV/J0/XwWs=";
  };

  npmDepsHash = "sha256-wA4/+wrR5saFGMCSLpEJVs1X9Lvpe3vYAQZN1TWFsKI=";

  prunePaths = [
    ".github"
    "test"
  ];
}
