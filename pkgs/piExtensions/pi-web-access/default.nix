{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-11-13";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "896d75bec55e316726db287a870eb166c4e3f40c";
    sha256 = "sha256-kvxwqQzvUEvBU8URxTCe4hGbWiUa41TbsdtdiM6+GqE=";
  };

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-6H9htKfObygFn6ZUOz6NwzsSXdSSYCXlkZYSc1Mq4oM=";
}
