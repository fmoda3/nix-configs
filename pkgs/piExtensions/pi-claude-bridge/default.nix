{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-claude-bridge";
  version = "0.11.0";

  src = fetchFromGitHub {
    owner = "elidickinson";
    repo = "pi-claude-bridge";
    rev = "debda8d669d978f0deba5249e32d7f6a2a489d86";
    sha256 = "sha256-94VxD3FND+fHwTlYmZvUKyp5X3BqMKoJifCawGCIZFk=";
  };

  npmDepsHash = "sha256-nS1KZnHHwTVV7B32tc7B7ZYssoPbKLo9GcXZr2Shot8=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
