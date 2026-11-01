{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-11-01";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "e9a31b3ea776587d18252616e292277db08a535c";
    sha256 = "sha256-nFsT9k333WixHIKRWDMoLfYnY0t2dBIofcFbGjUSXMU=";
  };

  npmDepsHash = "sha256-4iHfVe/7y5xTT3tu8hhbrjOMr8OpkvgpCiDdWqMGVoQ=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
