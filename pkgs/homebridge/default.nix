{ lib
, buildNpmPackage
, fetchFromGitHub
}:

buildNpmPackage rec {
  pname = "homebridge";
  version = "1.6.1";
  src = fetchFromGitHub {
    owner = "homebridge";
    repo = "homebridge";
    rev = "v${version}";
    hash = "sha256-U6cxnoqScwBrL+PN4regNSAZP97N9+whRNPpAtUBRc8=";
  };

  npmDepsHash = "sha256-/iOu8bnyoP7DdwJBrR6XXIMQuuwf4mP7m8FacuK3FuU=";

  meta = {
    description = "Homebridge";
    homepage = "https://github.com/homebridge/homebridge";
    license = lib.licenses.asl20;
    mainProgram = "homebridge";
    maintainers = with lib.maintainers; [ fmoda3 ];
  };
}
