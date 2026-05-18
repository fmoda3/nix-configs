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
    rev = "4ce9f4be94efbd0e80c21e5365128c4e051a3980";
    ref = "main";
    narHash = "sha256-j1Vsclj4W5TLd4IID7yLi3F3sL1FcD+brc9JH1lqHL0=";
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
