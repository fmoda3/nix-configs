{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-09-10";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "192ac1875e3b8f88c78953dbc314949ec9fcaa27";
    sha256 = "sha256-5YMwE44pyMmCapGt9kFLxT61Qg3OCzuJCIATRhMBv6M=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-0ScX5nMu3h8/KCysaeNiXj/DK7E3abY8LINAaAARhCc=";
}
