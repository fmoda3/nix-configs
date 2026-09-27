{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-09-26";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "c648b622ff2abd7f1038e3ad77e76e3f9fb08ccc";
    sha256 = "sha256-yUgimbiLrOiwua3xCU6RAUq06jh6kDv5TXlH5XL/oh4=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-AwwUA3jfEKY0vG8x8Z2cuiaaoCuf3xx7DbfF4aF7onw=";
}
