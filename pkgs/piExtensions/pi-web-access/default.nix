{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-07-28";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "b537183632d555d1b2e61cb8f6bdf585766f2380";
    sha256 = "sha256-lpM4H/b361Qg0pQD7Ncq7stYxPLIowg06k1xtHuXJNg=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-0yTT7lXf+C+s5So46h4tofInK0X3bq1unsRrXJ9gDDA=";
}
