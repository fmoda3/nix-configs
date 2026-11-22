{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-11-21";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "f5a745af5bf7c81fa55d47bf86c4afa25ac870e8";
    sha256 = "sha256-n6/CtO20p42yxKHazXOh0lcI0SjcCdpRmDtwS8f3qCY=";
  };

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-6H9htKfObygFn6ZUOz6NwzsSXdSSYCXlkZYSc1Mq4oM=";
}
