{ lib
, pkgs
, buildNpmPackage
, fetchFromGitHub
, nodejs_20
}:

buildNpmPackage rec {
  pname = "homebridge";
  version = "1.8.5";
  src = fetchFromGitHub {
    owner = "homebridge";
    repo = "homebridge";
    rev = "v${version}";
    hash = "sha256-zBzrfn4d6nPuotXIS97cX2H5GD/FSYfALrRv7LDIEis=";
  };

  nodejs = nodejs_20;

  npmDepsHash = "sha256-oQcotnMhw5MdlMm7le7nZ1dbJrHdlFZwsIeVAiMGBBw=";

  # Homebridge's clean phase attempts to install rimraf directly, which fails
  # rimraf is already in the declared dependencies, so we just don't need to do it.
  buildPhase = ''
    cat package.json | ${pkgs.jq}/bin/jq '.scripts.clean = "rimraf lib/"' > package.json.tmp
    mv package.json.tmp package.json
    npm run build
  '';

  meta = {
    description = "Homebridge";
    homepage = "https://github.com/homebridge/homebridge";
    license = lib.licenses.asl20;
    mainProgram = "homebridge";
    maintainers = with lib.maintainers; [ fmoda3 ];
  };
}
