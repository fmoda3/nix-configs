{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-claude-bridge";
  version = "0.13.0";

  src = fetchFromGitHub {
    owner = "elidickinson";
    repo = "pi-claude-bridge";
    tag = "v0.13.0";
    sha256 = "sha256-y7AU77cK1S1poglQA3UmnR8kul3LO3HB8dft5uJ+eMU=";
  };

  npmDepsHash = "sha256-CPwQO76XLihf2sSb5g1BeGKeVvBog7SrXEuNkFQNzQ0=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
