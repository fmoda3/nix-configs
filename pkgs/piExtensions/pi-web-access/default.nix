{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-09-30";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "72c6e67787d67d8a7d01bf0abf30c072a6112de6";
    sha256 = "sha256-GOT/Nym/oWLUHoO6zzvWnEeq+pXiTh/QF4VTY4vbT8s=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-ZOebioF4J3R4gl3RWiFJdlOsyIQ7BJJAYKQM6utiaa0=";
}
