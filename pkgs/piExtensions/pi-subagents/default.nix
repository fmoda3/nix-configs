{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-08-24";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "071fb76ae17cf3daae2c33f65e0e4bb8326f6a08";
    sha256 = "sha256-6DnalcLEStCO4SeXWGzhNoNB0ldv8MwH3vEka7TWo7w=";
  };

  npmDepsHash = "sha256-49BUnIE/jK1wnBYEAOsyCvMb6h82uNiJMnY7xTQRUdc=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
