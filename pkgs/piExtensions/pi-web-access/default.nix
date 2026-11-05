{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-11-05";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "322e44fafc1aaa691779cdf2116584e67edd7645";
    sha256 = "sha256-QfwEKSqOTc/VhPonFySNsgDAOkx9ROf+PnEF9v/iCow=";
  };

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-zceAHKLRFpT+RYcYo199+lf2+0Ly/DXtcB/U/QW7+m0=";
}
