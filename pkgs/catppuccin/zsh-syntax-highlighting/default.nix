{ stdenv
, fetchFromGitHub
}:
stdenv.mkDerivation {
  pname = "catppuccin-zsh-syntax-highlighting";
  version = "2024-07-20";

  src = fetchFromGitHub {
    owner = "catppuccin";
    repo = "zsh-syntax-highlighting";
    rev = "7926c3d3e17d26b3779851a2255b95ee650bd928";
    sha256 = "sha256-l6tztApzYpQ2/CiKuLBf8vI2imM6vPJuFdNDSEi7T/o=";
  };

  installPhase = ''
    mkdir -p $out/themes
    cp themes/* $out/themes
  '';
}
