{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-context";
  version = "2026-09-16";

  src = fetchFromGitHub {
    owner = "ttttmr";
    repo = "pi-context";
    rev = "b57bf17b538f29a2a53b9186cd6efd3c4d5efa53";
    sha256 = "sha256-oDxgUbAzyGaV4x43IRVrUDwTjQOl1bCT5apeyWZHK7Y=";
  };

  prunePaths = [ ".github" ];
}
