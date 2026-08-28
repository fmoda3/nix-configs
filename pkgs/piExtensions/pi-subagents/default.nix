{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-08-28";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "0987aa20b9a6b24d5f9d8ada1b58a05c63a57118";
    sha256 = "sha256-STSY308r6OQTTERjORj1J9mJpmAxDnvO1UCc8Xq19jQ=";
  };

  npmDepsHash = "sha256-BixrOUy1n+Xa4H88FP7lV08d2DfO0fhfGZBrg030MA0=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
