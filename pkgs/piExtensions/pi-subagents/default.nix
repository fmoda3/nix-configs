{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-08-26";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "e3987ad29b66fc4a1f152ebf8a2f2027da6f15fd";
    sha256 = "sha256-OZMEechBObVxF80iV8R1D0lhUB78cxzYaVADmnGitGc=";
  };

  npmDepsHash = "sha256-3F7yuZ5JSCGusVwmGqWriicHfUPxAKM5J2ePWnR6TYg=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
