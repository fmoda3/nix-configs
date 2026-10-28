{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-context";
  version = "2026-10-27";

  src = fetchFromGitHub {
    owner = "ttttmr";
    repo = "pi-context";
    rev = "03c2681c5e74ae35eef5ea6187ca264ac5a2232c";
    sha256 = "sha256-CuyvfmKmtQadB/CPVYDvVeVGbgxPFLMjG4WM797FLr8=";
  };

  prunePaths = [ ".github" ];
}
