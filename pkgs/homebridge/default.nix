{ lib
, buildNpmPackage
, fetchFromGitHub
, jq
,
}:

buildNpmPackage (finalAttrs: {
  pname = "homebridge";
  version = "2.0.0";

  src = fetchFromGitHub {
    owner = "homebridge";
    repo = "homebridge";
    tag = "v${finalAttrs.version}";
    hash = "sha256-KRDeS9qYefdafGpX8RF68ce6uSlS22aIRqJimmhI8Ko=";
  };

  npmDepsHash = "sha256-CkizIWaHzmotAr/64yY2wKAtqFoBdr5ylN5WcgdpMis=";

  meta = {
    description = "Lightweight emulator of iOS HomeKit API";
    homepage = "https://github.com/homebridge/homebridge";
    license = lib.licenses.asl20;
    mainProgram = "homebridge";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
    maintainers = with lib.maintainers; [ fmoda3 ];
  };
})
