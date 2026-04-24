{ lib
, stdenvNoCC
, buildNpmPackage
}:

args:
let
  builderArgs = removeAttrs args [
    "postInstallCommands"
    "prunePaths"
  ];

  prunePaths = args.prunePaths or [ ];
  pruneCommands = lib.concatMapStringsSep "\n"
    (path: ''
      rm -rf "$out/${path}"
    '')
    prunePaths;

  installPhase = args.installPhase or ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    ${pruneCommands}
    ${args.postInstallCommands or ""}

    runHook postInstall
  '';

  withInstallPhase = builderArgs // {
    inherit installPhase;
  };
in
if args ? npmDepsHash then
  buildNpmPackage
    (withInstallPhase // {
      dontNpmBuild = args.dontNpmBuild or true;
    })
else
  stdenvNoCC.mkDerivation withInstallPhase
