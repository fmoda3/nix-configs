{ lib
, buildNpmPackage
, nodejs
, toast
}:

buildNpmPackage (finalAttrs: {
  pname = "toast-bedrock-adapter";
  version = "2026-05-26";

  src = fetchGit {
    url = "git@github.toasttab.com:nathannorman-toast/toast-bedrock-adapter.git";
    rev = "7506a8475a3b34aa999de094f86ccb1a564a6f8d";
    ref = "main";
    narHash = "sha256-fyC/5gs6w4Bw2Q4z/Tw/HCp+2p0FjUwGBaS0kZOxNvM=";
  };

  npmDepsHash = "sha256-2sFtn11I8UreVQckBgs5VyK1Us2/wJylgHy87mU/LWY=";

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
