{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-11-26";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "4427fb2044adcd176ced091dc82ff787f3b039ff";
    sha256 = "sha256-g92Z6HdeKAfk9z06OcVCFILmUSN4N0S7UudSvlX6aBY=";
  };

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-6H9htKfObygFn6ZUOz6NwzsSXdSSYCXlkZYSc1Mq4oM=";
}
