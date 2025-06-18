{ stdenv
, fetchFromGitHub
}:
stdenv.mkDerivation {
  pname = "catppuccin-yazi";
  version = "1.0";

  src = fetchFromGitHub {
    owner = "catppuccin";
    repo = "yazi";
    rev = "1a8c939e47131f2c4bd07a2daea7773c29e2a774";
    sha256 = "sha256-hjqmNxIr/KCN9k5ZT7O994BeWdp56NP7aS34+nZ/fQQ=";
  };

  installPhase = ''
    mkdir -p $out/themes
    cp -r themes/* $out/themes
  '';
}
