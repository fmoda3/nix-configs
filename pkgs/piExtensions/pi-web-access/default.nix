{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-10-26";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "f6c2f54051bae8e57252d22acf03879117ac40bb";
    sha256 = "sha256-1tt/mmHUm711zyx4K/RqU8gVbtiTylVCT7yqsdJ9K6Q=";
  };

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-fw/HcePRMdJNNe+vNo4oBHWBUB9X2i2FAsl8BFr4qOc=";
}
