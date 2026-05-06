{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-ask";
  version = "2026-05-06";

  src = fetchFromGitHub {
    owner = "eko24ive";
    repo = "pi-ask";
    rev = "facc44b6c3e2e2964ed65075f1584b5b1db2eea0";
    sha256 = "sha256-p6Zc19PXBj5iAUGo1WhqBRdB+NzqNx6ZEu7pbTFAPHE=";
  };

  prunePaths = [ ".github" ];
}
