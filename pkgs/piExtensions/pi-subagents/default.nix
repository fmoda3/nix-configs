{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-09-23";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "4af5e85a427b9f87334585ae8d0eb365d4dd2a1e";
    sha256 = "sha256-KUnrfinRPiEPPdj0pd06MWnYncQmjiQvGySmGqdvwEg=";
  };

  npmDepsHash = "sha256-IwQZju9R2n0XxcPVVHzQejQ/Gihijy30Pq7cZ4kqN8E=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
