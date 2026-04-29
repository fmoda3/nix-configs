{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-ask";
  version = "0.6.1-unstable-2026-04-29";

  src = fetchFromGitHub {
    owner = "eko24ive";
    repo = "pi-ask";
    rev = "4153f6b09f97ca0242e1a06309e90c9ff35ae31e";
    sha256 = "sha256-8n9frJi5TxgbaGDK6lmQJbajpeVeO1lYPVJCjS4pNdU=";
  };

  prunePaths = [ ".github" ];
}
