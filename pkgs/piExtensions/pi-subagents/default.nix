{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-09-22";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "b9a0ce83dc7d552aa514105a89701a66fd37a00e";
    sha256 = "sha256-H0W9B1xWV9hCJDB7LvTzkSYBObzlBD0hcvvrDUAJOJU=";
  };

  npmDepsHash = "sha256-S6T0Y19PdpEwF3fbohGa7qPTS6tMZ52jCAv8luh436U=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
