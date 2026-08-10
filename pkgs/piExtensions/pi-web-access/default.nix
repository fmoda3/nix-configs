{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-08-09";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "692483ae782e41978fb2eba0eec70fd4056608c8";
    sha256 = "sha256-ZhkjziDbrzHGpbn1gEwrYCKt25XD+xrpfJxJTAuntg8=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-42NRWAN2fxwr0q3pAyWTb5F6PJ0siu5Ux01/Tamn0Ew=";
}
