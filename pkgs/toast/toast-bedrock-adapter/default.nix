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
    rev = "44d3287a353158b13e582d29523b6b196813cbd2";
    ref = "main";
    narHash = "sha256-XC7yNhBenL8umL/kArtCF0uLRpYRUHAjGLNLza07JIc=";
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
