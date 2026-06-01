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
  version = "2026-05-21";

  src = fetchGit {
    url = "git@github.toasttab.com:toasttab/oktoast-setup.git";
    rev = "482ce77a1c095285fb5a8ae1017bfb61560fde04";
    narHash = "sha256-dj7+Ei4v1ZA5sN1Sxd9CZAiK5x5aby9CmGgIATmpMWk=";
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
