{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-08-12";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "06eb40e990e855395ddae5b9ed0dda60e4736199";
    sha256 = "sha256-2nUyspIkuQ6I1OdNtsylCxqWhzX91c7ct4Zt2I7GHgc=";
  };

  npmDepsHash = "sha256-FLPZDWGYJ1RaGc54ACNgzstgBcAxEI27QvoGJZBQj74=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
