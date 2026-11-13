{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-11-11";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "fed16958bdf66c96395f67156a148c8726ae3ab6";
    sha256 = "sha256-1tjfFWfvGvMo+JILF3RGP1i1Sc9+PK18sOT1aS/hh+o=";
  };

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-zceAHKLRFpT+RYcYo199+lf2+0Ly/DXtcB/U/QW7+m0=";
}
