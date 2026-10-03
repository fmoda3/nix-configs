{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-10-03";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "a487fc5fdfeb1bd436878365104ce0035ed30274";
    sha256 = "sha256-PN5zfWHXpbVR5dDIXnZS3PywTLOxIvDexAWkl0tXcuw=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-gll508NRuMiuFTNIP+i8MbcepMXyXtwmC4HLRUtoGMA=";
}
