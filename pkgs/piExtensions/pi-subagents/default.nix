{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-08-11";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "69cb4dc830a197e66d60b79ba31946ac41efe324";
    sha256 = "sha256-Uoq0SqpwnVLWy4rvdMNKzGpzqvrAi9JhSwxYrpsiTgo=";
  };

  npmDepsHash = "sha256-knLTptogmWojkd6btqua4JXSv269APx6Z1wPMHvWm2Y=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
