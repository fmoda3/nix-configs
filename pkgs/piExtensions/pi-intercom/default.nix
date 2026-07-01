{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-intercom";
  version = "0.6.0";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-intercom";
    rev = "9f23b97d5b3e9e8f28f2c1aac6ff326408bf7177";
    sha256 = "sha256-waHyZuzhsAJ0X02t07P/UXW5Rzy0hoc6lubUh8i4DN4=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-KNETPl4rV2IHiWChy1megGIjxPIc6NudQ0FOEH3J/Xs=";
}
