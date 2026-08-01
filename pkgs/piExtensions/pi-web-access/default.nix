{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-07-31";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "2a186dbebab7be605d8c615ae33dd3f2e649666b";
    sha256 = "sha256-OAalqzzUhYd2W5wAhX80u5jxseVujJ3GBRU6+uWCTtk=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-42NRWAN2fxwr0q3pAyWTb5F6PJ0siu5Ux01/Tamn0Ew=";
}
