{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-context";
  version = "2026-07-27";

  src = fetchFromGitHub {
    owner = "ttttmr";
    repo = "pi-context";
    rev = "9057e10226e0ff9a1e1c2cd2c3bd81913d69d2a5";
    sha256 = "sha256-/pxUR2R/1QywYE4ZvAOSyPglmuFDZYcV5386CmNFgwU=";
  };

  prunePaths = [ ".github" ];
}
