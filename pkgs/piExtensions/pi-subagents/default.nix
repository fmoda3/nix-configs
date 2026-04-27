{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-04-26";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "564a63a0c0d0c84d124bbbb80ad446607fcb7a67";
    sha256 = "sha256-PRFnEbRplASaiH8VJYMIw1O31JyIPl5cx6d2MEZB13g=";
  };

  prunePaths = [ ".github" ];
}
