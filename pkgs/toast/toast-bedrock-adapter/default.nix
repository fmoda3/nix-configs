{ lib
, buildNpmPackage
, nodejs
, toast
}:

buildNpmPackage (finalAttrs: {
  pname = "toast-bedrock-adapter";
  version = "2026-06-29";

  src = fetchGit {
    url = "git@github.toasttab.com:nathannorman-toast/toast-bedrock-adapter.git";
    rev = "4803b048efcc3c3e8fec396ceda1b1cd88a03b03";
    ref = "main";
    narHash = "sha256-SetBtcy3m5bCKEyFoj/IKS6f2wYW+JEYzQfK13VmuYg=";
  };

  npmDepsHash = "sha256-AQToJ+oGPHIO0zyHjZlxZDOuexIq/AZu9vf9R8Axaqc=";

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
