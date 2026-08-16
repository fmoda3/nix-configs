{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-08-16";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "e973fa3c717bb32546a55ca7f061fd10ed6f7427";
    sha256 = "sha256-7NLI3oaZu1vqF6kSqSigVKa0Vh9JpaLXYlgy/v8hudI=";
  };

  npmDepsHash = "sha256-EvC8EVfkJXrzYdu5K4CSVNoFuZQ9nvUlzmRNhA0pf2A=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
