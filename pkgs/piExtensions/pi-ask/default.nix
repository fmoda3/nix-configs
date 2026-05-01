{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-ask";
  version = "2026-04-28";

  src = fetchFromGitHub {
    owner = "eko24ive";
    repo = "pi-ask";
    rev = "4153f6b09f97ca0242e1a06309e90c9ff35ae31e";
    sha256 = "sha256-8n9frJi5TxgbaGDK6lmQJbajpeVeO1lYPVJCjS4pNdU=";
  };

  prunePaths = [ ".github" ];
}
