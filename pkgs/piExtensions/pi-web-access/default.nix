{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-10-05";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "9a0779976ba47350be18f8cfacaffbe2a407113e";
    sha256 = "sha256-bFaxlTVmNiPWXK1gBIhKr7VSsC2MS1ciR/iEAAyRvn4=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-BuRoUb5XohX6TxNRYrGiMdikK4o9tIbew04tifEdYzQ=";
}
