{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-08-21";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "2409b17b872873cc754f0e82996119c53600b4dc";
    sha256 = "sha256-H/TqEu4J1vXKVtI5z5F8kLchFhkmSz5HqXxwGL/wwHM=";
  };

  npmDepsHash = "sha256-er9ICjNnlyp9MHsTRH6yDwDfCjz02SDCW8yrkM8o19E=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
