{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-claude-bridge";
  version = "0.9.3";

  src = fetchFromGitHub {
    owner = "elidickinson";
    repo = "pi-claude-bridge";
    rev = "0b41f78189de09c6da6baf3acc0f604b089f08fb";
    sha256 = "sha256-8asHumCj7UrQsa3Niogq4U1RAuqt2OEIBirQyHtKNJE=";
  };

  npmDepsHash = "sha256-C6feY0M1znfiGeHheaNN1jlbmBM7DOPscpA+TNdNNqQ=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
