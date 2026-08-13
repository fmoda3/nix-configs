{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-08-13";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "60c8baee44ee91746a3622a1bbdb0aa4a8ebc665";
    sha256 = "sha256-DaKbc1ldF6n95aMRFgsbY7XEDTdc3WEAydTCHFSahNQ=";
  };

  npmDepsHash = "sha256-kCvGgbIGNyHtimOw//7+oaZ7FHO8xEruq9CCtTR658M=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
