{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-claude-bridge";
  version = "0.11.0";

  src = fetchFromGitHub {
    owner = "elidickinson";
    repo = "pi-claude-bridge";
    rev = "334c2b689d7c2bd047b5ad278bca5d4ccd8c5682";
    sha256 = "sha256-GJGohRn55sfuizR9d/qBrBGiue6ABTN8XWjmYGOhAFA=";
  };

  npmDepsHash = "sha256-nS1KZnHHwTVV7B32tc7B7ZYssoPbKLo9GcXZr2Shot8=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
