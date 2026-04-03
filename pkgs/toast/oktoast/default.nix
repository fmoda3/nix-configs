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
  version = "2.36.0";

  src = fetchGit {
    url = "git@github.toasttab.com:toasttab/oktoast-setup.git";
    rev = "d0d0580784f1d5ae7fe8ed72f4df8df807a5e01d";
    narHash = "sha256-gCtrZqMPH3BZ4HvFZowNiTXHeK2A1lbLXRdokV8/1Xw=";
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
