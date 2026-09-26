{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-09-26";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "fe4b7719ccd9b7e44526850259b2264c19ba8899";
    sha256 = "sha256-X99magpK0lG4rJD1qvUh14Fz9eNecBU1WTWXtFIYk8o=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-Bmld646Il9J89irhuoYQnP/MOHGeDEfraIQ+GD109HQ=";
}
