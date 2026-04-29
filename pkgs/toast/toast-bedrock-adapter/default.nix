{ lib
, buildNpmPackage
, nodejs
, toast
}:

buildNpmPackage (finalAttrs: {
  pname = "toast-bedrock-adapter";
  version = "1.4.0";

  src = fetchGit {
    url = "git@github.toasttab.com:nathannorman-toast/toast-bedrock-adapter.git";
    rev = "78912c562f55b31d6a34b4fa53f61484da482be6";
    ref = "main";
    narHash = "sha256-NpaVa/YGkaS/1vWwxw527ExmmHEXyl8b9fSKADwkydo=";
  };

  npmDepsHash = "sha256-eX7UtU2/J+rAdwqsWcjc0xWuxEAyl7ibn7U45pjIdyc=";

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
