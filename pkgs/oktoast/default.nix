{ stdenv, fetchFromGitHub, pkgs }:
stdenv.mkDerivation {
  pname = "oktoast";
  version = "1.0";

  src = fetchGit {
    url = "git@github.com:toasttab/oktoast-setup.git";
    rev = "9c11ea8337143a597d088d4a75a10424d82f45ee";
  };

  installPhase = ''
    mkdir -p $out/bin
    cp oktoast $out/bin
  '';
}