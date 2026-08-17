{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-08-17";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "189a773cd85e85185476f36a3579540607fa886c";
    sha256 = "sha256-ZOZsXm6+r1TEhw1nCb2IaTAzZnN9S5nY2VAGxdjAN/k=";
  };

  npmDepsHash = "sha256-EvC8EVfkJXrzYdu5K4CSVNoFuZQ9nvUlzmRNhA0pf2A=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
