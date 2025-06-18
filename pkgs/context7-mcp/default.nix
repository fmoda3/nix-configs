{ lib
, buildNpmPackage
, fetchFromGitHub
}:

buildNpmPackage (finalAttrs: {
  pname = "context7-mcp";
  version = "1.0.14";

  src = fetchFromGitHub {
    owner = "upstash";
    repo = "context7";
    tag = "v${finalAttrs.version}";
    hash = "sha256-41CIl3+psA/UPYclq7hnNvuhAaUg9NPuAZETGPbrydo=";
  };

  npmDepsHash = "sha256-h58pfnN/kql9y0akIn9Ps6ecRckX0pM/RidyeAman/g=";

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  meta = {
    description = "Context7";
    homepage = "https://github.com/upstash/context7";
    license = lib.licenses.mit;
    mainProgram = "context7-mcp";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
    maintainers = with lib.maintainers; [ fmoda3 ];
  };
})
