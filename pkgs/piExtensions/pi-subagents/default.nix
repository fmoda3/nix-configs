{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-08-20";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "60f9dd11b9e39478a6a8e54b90f2f7fc83657853";
    sha256 = "sha256-jXJhTy+Om6OK5oXRQcidcQWFyQT1zBpMjKFbo06/V+Q=";
  };

  npmDepsHash = "sha256-1QkiBibN6xNjbtuifV6yOg6nZ5zzU0oBVuC1cwXofDI=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
