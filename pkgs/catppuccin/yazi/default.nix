{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "catppuccin-yazi";
  version = "2026-05-14";

  src = fetchFromGitHub {
    owner = "catppuccin";
    repo = "yazi";
    rev = "41f24ed142e34109a9a65a5dfe58c1b4eb6d2fd9";
    sha256 = "sha256-Og33IGS9pTim6LEH33CO102wpGnPomiperFbqfgrJjw=";
  };

  installPhase = ''
    mkdir -p $out/themes
    cp -r themes/* $out/themes
  '';
}
