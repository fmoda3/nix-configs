{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-08-22";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "846949c645efadd6314f25eef60b390b0669704a";
    sha256 = "sha256-GWP1lpBkCzzET4EcsigH50k988DDNry3AB9PE6p+zRU=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-BJaGW1EfSTM7bWcSCq8R7AwtWYSsHgkYttxHyPGXcd4=";
}
