{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-10-21";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "d0e323ac935e8753d11e1853b81c057e39dee4dc";
    sha256 = "sha256-/NQbfQTheJ8Di5l3ZP8pbWqAKqrhJ2F6OsiZAKt59YI=";
  };

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-fw/HcePRMdJNNe+vNo4oBHWBUB9X2i2FAsl8BFr4qOc=";
}
