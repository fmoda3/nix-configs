{ stdenv
, fetchFromGitHub
}:
stdenv.mkDerivation {
  pname = "catppuccin-yazi";
  version = "2025-12-29";

  src = fetchFromGitHub {
    owner = "catppuccin";
    repo = "yazi";
    rev = "fc69d6472d29b823c4980d23186c9c120a0ad32c";
    sha256 = "sha256-Og33IGS9pTim6LEH33CO102wpGnPomiperFbqfgrJjw=";
  };

  installPhase = ''
    mkdir -p $out/themes
    cp -r themes/* $out/themes
  '';
}
