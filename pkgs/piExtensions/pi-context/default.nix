{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-context";
  version = "2026-09-08";

  src = fetchFromGitHub {
    owner = "ttttmr";
    repo = "pi-context";
    rev = "3c8ff09e49cb905d778ca6059ee3d161cce55a0e";
    sha256 = "sha256-z7zHzEscp2yOJTcEe+YVJQgAIig4Xrt1GzpQiGN2rIU=";
  };

  prunePaths = [ ".github" ];
}
