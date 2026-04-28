{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-tasks";
  version = "2026-04-28";

  src = fetchFromGitHub {
    owner = "tintinweb";
    repo = "pi-tasks";
    rev = "d47a9acb861bede4c476c6e0fa50145940d35c5b";
    sha256 = "sha256-7Fbap7TaoGZu9klMDsLXCQ4r5TkRAvNYRTAhNaIkIIg=";
  };

  npmDepsHash = "sha256-ng0q5Ml2hWPBV7cAnbqCRPukWCCC7WeANcEvyTYPO9c=";

  prunePaths = [
    ".github"
    "test"
    "media"
  ];
}
