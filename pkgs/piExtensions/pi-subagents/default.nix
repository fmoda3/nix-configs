{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-11-16";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "4aa4ddb0ecb7ad56a6c9e56c96f39f7877a1550f";
    sha256 = "sha256-DTe0j9JQfsXD3O9eeu/Tz7cnvsdM2bjtn63wqHYphu8=";
  };

  npmDepsHash = "sha256-Fx47aupm5P6xV3Fq8kQxs0u7gYNADTnbIZcmpQRdG28=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
