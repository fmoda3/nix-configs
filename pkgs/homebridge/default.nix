{ lib
, buildNpmPackage
, fetchFromGitHub
, nodejs_20
}:

buildNpmPackage rec {
  pname = "homebridge";
  version = "1.8.0";
  src = fetchFromGitHub {
    owner = "homebridge";
    repo = "homebridge";
    rev = "v${version}";
    hash = "sha256-hnwnzlhFnE4FS9ly6BoJr4HqAXbhzWqGTGe7BgqczD4=";
  };

  nodejs = nodejs_20;

  npmDepsHash = "sha256-3jxsBtOSR2J1kqOf1X0yGx/W0CPNb8adg+6tpmfGY6M=";

  meta = {
    description = "Homebridge";
    homepage = "https://github.com/homebridge/homebridge";
    license = lib.licenses.asl20;
    mainProgram = "homebridge";
    maintainers = with lib.maintainers; [ fmoda3 ];
  };
}
