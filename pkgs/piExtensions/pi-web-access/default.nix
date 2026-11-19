{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-11-19";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "438e58be6307efb7cd539af3806757abe303aa0c";
    sha256 = "sha256-toUZGgyZQ9pbAl2aPFlYo3xH8m/42ptVzkY99DuZE1Y=";
  };

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-6H9htKfObygFn6ZUOz6NwzsSXdSSYCXlkZYSc1Mq4oM=";
}
