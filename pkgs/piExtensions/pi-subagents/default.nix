{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-08-06";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "ebb2917f2b5234e7f167ba6cede392386880d579";
    sha256 = "sha256-/KUZFpiPTMKzgoj59H8tsEAu4xm8cdcEvregPNt8+hA=";
  };

  npmDepsHash = "sha256-4P4t0iaX0yWMGMc0dsYDKGo0VgT0oni5bnX0AI/L8nY=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
