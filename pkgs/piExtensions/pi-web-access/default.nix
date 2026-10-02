{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-10-02";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "4c61056cec03c247bdfe725e9bc255eb1756ea81";
    sha256 = "sha256-H1Xm2c5cZUcxF5YeeM866rBEIAtivLfQlAzZAP5KBsk=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-gll508NRuMiuFTNIP+i8MbcepMXyXtwmC4HLRUtoGMA=";
}
