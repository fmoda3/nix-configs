{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-08-19";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "e83c707dbdf8f7bfae321ed99f06ce67258b50bd";
    sha256 = "sha256-UIROHvSGMghRetk9lWJezbk/hKesz5cRuHeAM+IkpWI=";
  };

  npmDepsHash = "sha256-kJqaHv5+vHj8F1QpK9ocsoXetdCoTtqC8aEq92yvUKk=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
