{ lib
, pkgs
, buildNpmPackage
, fetchFromGitHub
}:
let
  version = "0.122.0";
  src = fetchFromGitHub {
    owner = "koush";
    repo = "scrypted";
    rev = "v${version}";
    hash = "sha256-G3XUjpISypTUxtZce8sGBZ42qWemvgTOx7KVu+uGcwa=";
  };
in
buildNpmPackage rec {
  pname = "scrypted";
  inherit version;
  src = "${src}/server";

  npmDepsHash = "sha256-oQcotnMhw5MdlMm7le7nZ1dbJrHdlFZwsIeVAiMGBBo=";

  nativeBuildInputs = [
    python3
  ] ++ lib.optionals stdenv.hostPlatform.isDarwin [
    xcbuild
  ];

  meta = {
    description = "A home video integration and automation platform";
    homepage = "https://www.scrypted.app/";
    license = lib.licenses.isc;
    mainProgram = "scrypted-serve";
    maintainers = with lib.maintainers; [ fmoda3 ];
  };
}
