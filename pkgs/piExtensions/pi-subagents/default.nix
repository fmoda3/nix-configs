{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-08-16";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "27784eed57dd62021a7add4990ac2dada6690baa";
    sha256 = "sha256-psCcyGisLAwOWTVtTk8Mf+LlmvN8uM0k2lknonSi9SY=";
  };

  npmDepsHash = "sha256-EvC8EVfkJXrzYdu5K4CSVNoFuZQ9nvUlzmRNhA0pf2A=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
