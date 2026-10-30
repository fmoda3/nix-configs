{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-10-29";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "a04617faa1f4d7daf631fefc10afc76412c6fe4a";
    sha256 = "sha256-5eeE7n2fZS5v2IbrEnCVWf2aoLNRmkMtYmNGB1sFntk=";
  };

  npmDepsHash = "sha256-4iHfVe/7y5xTT3tu8hhbrjOMr8OpkvgpCiDdWqMGVoQ=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
