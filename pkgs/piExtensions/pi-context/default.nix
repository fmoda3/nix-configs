{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-context";
  version = "2026-10-16";

  src = fetchFromGitHub {
    owner = "ttttmr";
    repo = "pi-context";
    rev = "2ca02eecc4c535ca8a907c023d93e1e446b9690c";
    sha256 = "sha256-bAR2zI71NBCn4sOBgUFDNcBniIGxDsWHHc8uMoXGBv0=";
  };

  prunePaths = [ ".github" ];
}
