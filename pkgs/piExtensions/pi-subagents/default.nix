{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-07-31";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "a03a5dab801b4ba3f55166d766776adc76e8d137";
    sha256 = "sha256-KXiBcaYCb1Zg1vx6cG+bSucxGX0Rr2WfHj4cnLtZrAM=";
  };

  npmDepsHash = "sha256-8iy7AuWah3zI3ciLzqGnvtF57LE4qSUmljDyTyQ3tdY=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
