{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-context";
  version = "2026-06-02";

  src = fetchFromGitHub {
    owner = "ttttmr";
    repo = "pi-context";
    rev = "b55558cdde91797a4dfd04a24f0f590307e248d1";
    sha256 = "sha256-rx6kIKD1fdva9U5jWRsBoaM+MnEGkhpedYhpbZcyG5Y=";
  };

  prunePaths = [ ".github" ];
}
