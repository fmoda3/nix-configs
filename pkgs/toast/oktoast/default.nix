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
  version = "2026-07-27";

  src = fetchGit {
    url = "git@github.toasttab.com:toasttab/oktoast-setup.git";
    rev = "41ee247f2819268d45582872c5eded6dd1d92616";
    narHash = "sha256-pie13g1kMLR/oicE7lhlMaLYOY8RwzR/IVg096sedpM=";
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
