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
  version = "2026-09-22";

  src = fetchGit {
    url = "git@github.toasttab.com:toasttab/oktoast-setup.git";
    rev = "ed8cb6c684a7985c7327d4503bd43786ca8ecec5";
    ref = "master";
    narHash = "sha256-kSclUjDtPsxmt5RiCx7TgzJ7z8FKeS7oHjTcAlwB2SY=";
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
