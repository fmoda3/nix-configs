{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-09-14";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "83af77e6dfd4bca8e884712dd4dfd252fd4c1c44";
    sha256 = "sha256-oCIPbrW3Ppcv6Ge5oP3Gy7UMusNJCC+7sdvs1bcTLfU=";
  };

  npmDepsHash = "sha256-7kM9B2Yzadl76BTX0ZBSmQH33EAwUQ0B3+gVX8pS/GA=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
