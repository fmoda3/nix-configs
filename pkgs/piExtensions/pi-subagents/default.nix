{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-09-22";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "0ac924ab5ae9f7c3cc25158245d2a18b4c253d2e";
    sha256 = "sha256-y2QXX364q0okmICxVJtGWrfP/ISsY5B705NpEdtRow8=";
  };

  npmDepsHash = "sha256-S6T0Y19PdpEwF3fbohGa7qPTS6tMZ52jCAv8luh436U=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
