{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-08-06";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "d84ef67073d14aeaf3644a8aabe2b1cf784719fd";
    sha256 = "sha256-Uzy3Vn2JZUXwG0SOV7Aa3ztYi5fhv3KgHiRwQ0JeVbk=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-42NRWAN2fxwr0q3pAyWTb5F6PJ0siu5Ux01/Tamn0Ew=";
}
