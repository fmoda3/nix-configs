{ stdenv, fetchFromGitHub, pkgs, lib }:
stdenv.mkDerivation {
  pname = "oktoast";
  version = "1.0";

  src = fetchGit {
    url = "git@github.com:toasttab/oktoast-setup.git";
    rev = "9c11ea8337143a597d088d4a75a10424d82f45ee";
  };

  nativeBuildInputs = [
    pkgs.makeWrapper
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp oktoast $out/bin
  '';

  postFixup = ''
    wrapProgram $out/bin/oktoast \
      --prefix PATH : ${lib.makeBinPath [
        pkgs.saml2aws
        # gnused installs "sed", but oktoast needs "gsed"
        (pkgs.writeShellScriptBin "gsed" "exec -a $0 ${pkgs.gnused}/bin/sed \"$@\"")
        pkgs.awscli
      ]}
  '';
}