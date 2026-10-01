{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-10-01";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "ba36f6a3fad8abad3836e3c005ef7aecf2b886d2";
    sha256 = "sha256-u981hwTpwhylByiQZTdKTxlIuGtYMSdlRamn8Zrm/Lo=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-ZOebioF4J3R4gl3RWiFJdlOsyIQ7BJJAYKQM6utiaa0=";
}
