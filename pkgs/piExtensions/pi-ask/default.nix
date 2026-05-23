{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-ask";
  version = "2026-05-22";

  src = fetchFromGitHub {
    owner = "eko24ive";
    repo = "pi-ask";
    rev = "bf3c26d9aa03a7d6128e122705b5740294d3d5e6";
    sha256 = "sha256-O0Nazvn7w9+8u+Hp61V1w5nLBdImgiz7tuEDKlMEyZk=";
  };

  prunePaths = [ ".github" ];
}
