{ lib
, buildNpmPackage
, fetchgit
, nodejs
, toast
}:

buildNpmPackage (finalAttrs: {
  pname = "toast-bedrock-adapter";
  version = "1.4.0";

  src = fetchgit {
    url = "git@github.toasttab.com:nathannorman-toast/toast-bedrock-adapter.git";
    rev = "2f70872cc67ace9de40e271172e21c32c6946ba2";
    hash = "sha256-+htEu5R9WdC5kXd1qOkGN4NVJSYZzscKwS5xXgQCsNo=";
  };

  npmDepsHash = "sha256-kEiGzVB1pRUnj51AnN2TH3OXD3Jz3kPNbqPYaQhOP9Y=";

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
