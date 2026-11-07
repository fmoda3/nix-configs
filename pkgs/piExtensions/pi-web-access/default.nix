{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-11-06";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "6dd57b7f5a0c3041053e65a28f5f425323ec95f9";
    sha256 = "sha256-sirC0nARXxmLfXRX0ExnFxSlV6kRMb36RfVROyABKJI=";
  };

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-zceAHKLRFpT+RYcYo199+lf2+0Ly/DXtcB/U/QW7+m0=";
}
