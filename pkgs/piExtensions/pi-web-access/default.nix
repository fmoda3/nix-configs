{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-10-15";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "d47dc040552505e3b135d0136a0b15eaf4bdba52";
    sha256 = "sha256-rO7rj3RVS/79cUpWUZCXktaxJbjLO4QDPezRTn+H120=";
  };

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-9dJqmTQc80Ny+dAzyH2OkCfKTnlUZ54w28E4lwVOvNE=";
}
