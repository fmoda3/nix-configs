{ stdenv
, lib
, makeWrapper
, writeShellScriptBin
, saml2aws
, gnused
, awscli
}:
stdenv.mkDerivation {
  pname = "oktoast";
  version = "2026-01-13";

  src = fetchGit {
    url = "git@github.toasttab.com:toasttab/oktoast-setup.git";
    rev = "8a029f7db84d4eeb07975e62dd0f6b4971f02447";
  };

  nativeBuildInputs = [
    makeWrapper
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp oktoast $out/bin
  '';

  postFixup = ''
    wrapProgram $out/bin/oktoast \
      --prefix PATH : ${lib.makeBinPath [
        saml2aws
        # gnused installs "sed", but oktoast needs "gsed"
        (writeShellScriptBin "gsed" "exec -a $0 ${gnused}/bin/sed \"$@\"")
        awscli
      ]}
  '';
}
