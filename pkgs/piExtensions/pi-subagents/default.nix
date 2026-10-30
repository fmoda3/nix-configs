{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-10-30";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "a37a28853822d470d15ae1764c97aed258087699";
    sha256 = "sha256-YqeQF9SzelM7ACBag7tkLfxEqhPmCOCTmna0cPb0Tgw=";
  };

  npmDepsHash = "sha256-4iHfVe/7y5xTT3tu8hhbrjOMr8OpkvgpCiDdWqMGVoQ=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
