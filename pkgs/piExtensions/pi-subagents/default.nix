{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-10-22";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "1bc941363cb62fc23c94c5519364b03dc150be3e";
    sha256 = "sha256-qK0lB1TKBWvFixp7kPikAdsxEtdP4g924GPy3+61wIw=";
  };

  npmDepsHash = "sha256-O+VByGju1YEhiHy1ic+I30YED5wVXSeIgabN4dJnzK0=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
