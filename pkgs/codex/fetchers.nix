# not a stable interface, do not reference outside the codex package but make a copy if you need
{ lib
, stdenv
, fetchurl
,
}:
let
  releaseUrl = version: "https://github.com/openai/codex/releases/download/rusty-v8-v${version}";
  target = stdenv.hostPlatform.rust.rustcTarget;
in
{
  fetchLibrustyV8 =
    args:
    fetchurl {
      name = "librusty_v8-${args.version}";
      url = "${releaseUrl args.version}/librusty_v8_ptrcomp_sandbox_release_${target}.a.gz";
      sha256 = args.shas.${stdenv.hostPlatform.system};
      meta = {
        inherit (args) version;
        sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
      };
    };

  fetchRustyV8Binding =
    args:
    fetchurl {
      name = "src_binding-${args.version}.rs";
      url = "${releaseUrl args.version}/src_binding_ptrcomp_sandbox_release_${target}.rs";
      sha256 = args.shas.${stdenv.hostPlatform.system};
    };
}
