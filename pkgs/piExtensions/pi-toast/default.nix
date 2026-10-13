{ buildPiExtension }:

buildPiExtension {
  pname = "pi-toast";
  version = "2026-10-13";

  src = fetchGit {
    url = "git@github.toasttab.com:toasttab/pi-toast.git";
    rev = "2e326da53a367d6946bbd57378e9d019afe680bb";
    ref = "main";
    narHash = "sha256-TqEHfPbDMN3tXQAWnfs67HlJaZkyZd8gPTvhsf1un+k=";
  };

  npmDepsHash = "sha256-wA4/+wrR5saFGMCSLpEJVs1X9Lvpe3vYAQZN1TWFsKI=";

  prunePaths = [
    ".github"
    "test"
  ];
}
