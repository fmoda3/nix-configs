{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-10-17";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "18e36f9e0fc2de3c9895a7fda8d39a62ce60f49e";
    sha256 = "sha256-rgjfhflCgX69I0G//smtegna4PnONVkgIXt1T+L9zjQ=";
  };

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-KaKklBlBM5BaQdRz0Fp17HuRcuocuinYL8l45O1L694=";
}
