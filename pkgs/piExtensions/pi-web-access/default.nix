{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-09-23";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "610a52033f1e9705c0023ff9e0fac399319310a3";
    sha256 = "sha256-ykR2slh8MkxxbP660h0rvk2Y7SaKv+Cw/lJC21JqGW8=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-Bmld646Il9J89irhuoYQnP/MOHGeDEfraIQ+GD109HQ=";
}
