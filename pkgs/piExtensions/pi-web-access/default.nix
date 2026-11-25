{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-11-25";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "28042af704a1fb6c86d6c62cc26bc2a2e68b5f8a";
    sha256 = "sha256-M2Hhs7AVjQsn8rIbphheUzNu2EO3iTIkAPR1NzeoX9Q=";
  };

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-6H9htKfObygFn6ZUOz6NwzsSXdSSYCXlkZYSc1Mq4oM=";
}
