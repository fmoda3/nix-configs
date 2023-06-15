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
  version = "1.0";

  src = fetchGit {
    url = "git@github.com:toasttab/oktoast-setup.git";
    rev = "149893783ff9f20779c66772a87cbde073dee2af";
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
