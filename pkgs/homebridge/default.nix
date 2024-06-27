{ lib
, buildNpmPackage
, fetchFromGitHub
, nodejs_20
}:

buildNpmPackage rec {
  pname = "homebridge";
  version = "1.8.3";
  src = fetchFromGitHub {
    owner = "homebridge";
    repo = "homebridge";
    rev = "v${version}";
    hash = "sha256-fkIIZ0JbF/wdBWUIxoCP2Csv0w0I/3Xi/A+s79vcNWU=";
  };

  nodejs = nodejs_20;

  npmDepsHash = "sha256-11f+RDrGtdbXX0U7oJT3Pp6w4ILCG36BPDXzmjkpppU=";

  meta = {
    description = "Homebridge";
    homepage = "https://github.com/homebridge/homebridge";
    license = lib.licenses.asl20;
    mainProgram = "homebridge";
    maintainers = with lib.maintainers; [ fmoda3 ];
  };
}
