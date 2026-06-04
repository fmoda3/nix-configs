{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-context";
  version = "2026-06-04";

  src = fetchFromGitHub {
    owner = "ttttmr";
    repo = "pi-context";
    rev = "f3886fa544d47d3084ca990532100f69342f79e7";
    sha256 = "sha256-A/YqBJSmk+Yv1R/HZrqBb6d34QUsQVX/QVTabghQMok=";
  };

  prunePaths = [ ".github" ];
}
