{ lib
, buildGoModule
, makeWrapper
, saml2aws
, awscli2
, fzf
, jq
}:
buildGoModule {
  pname = "oktoast";
  version = "2026-06-29";

  src = fetchGit {
    url = "git@github.toasttab.com:toasttab/oktoast-setup.git";
    rev = "d67799d6f04358e765ffa3f0994d28f0db5806a7";
    narHash = "sha256-JkuoLPx5ItXR+PrsqjEdr0IGVk3E/bCfsEdOguQaSo4=";
  };

  vendorHash = "sha256-fIm9Qqr+BYIx7qxtDGGREHR/fVPcG2sVqPQI17EcuiA=";

  nativeBuildInputs = [ makeWrapper ];

  postFixup = ''
    wrapProgram $out/bin/oktoast \
      --prefix PATH : ${lib.makeBinPath [
        saml2aws
        awscli2
        fzf
        jq
      ]}
  '';
}
