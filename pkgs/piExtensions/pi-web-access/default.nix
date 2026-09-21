{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-09-21";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "7beed5db02261e717e81f855cdea6dff6ab34a40";
    sha256 = "sha256-UxyaCbQRgVV1rQ6CPRmuzFKoPsCTGYPBBKVvrpPkXS8=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-Bmld646Il9J89irhuoYQnP/MOHGeDEfraIQ+GD109HQ=";
}
