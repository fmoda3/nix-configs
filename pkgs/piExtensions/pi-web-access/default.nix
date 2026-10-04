{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-10-03";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "c947cf685fcae3989722b02a94499caa47f5fee6";
    sha256 = "sha256-4h5EDZsnc5DeGNUrvb6gY5vdfy6uDSIGfpVqBe6YpjM=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-gll508NRuMiuFTNIP+i8MbcepMXyXtwmC4HLRUtoGMA=";
}
