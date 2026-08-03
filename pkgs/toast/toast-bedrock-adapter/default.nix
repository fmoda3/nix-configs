{ lib
, buildNpmPackage
, nodejs
, toast
}:

buildNpmPackage (finalAttrs: {
  pname = "toast-bedrock-adapter";
  version = "2026-07-29";

  src = fetchGit {
    url = "git@github.toasttab.com:nathannorman-toast/toast-bedrock-adapter.git";
    rev = "781eb6d4f3dd30b0ce799f20f8cb54830a79cc89";
    ref = "main";
    narHash = "sha256-/GejF3zgUQugXbbOXl6Fmzp1DXCXVuUQkt+0Db7paAM=";
  };

  npmDepsHash = "sha256-Q7rikVQMcVRv0PiD659kOBk+pLwnIB3gJbTuIffMdUQ=";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib/node_modules/toast-bedrock-adapter
    cp -r . $out/lib/node_modules/toast-bedrock-adapter/

    makeWrapper ${nodejs}/bin/node $out/bin/toast-bedrock-adapter \
      --add-flags "$out/lib/node_modules/toast-bedrock-adapter/bin/toast-bedrock-adapter.js" \
      --prefix PATH : ${lib.makeBinPath [ toast.bedrock-llm-proxy ]}

    runHook postInstall
  '';
})
