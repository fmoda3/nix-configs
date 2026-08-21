{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "catppuccin-yazi";
  version = "2026-08-20";

  src = fetchFromGitHub {
    owner = "catppuccin";
    repo = "yazi";
    rev = "d62802be39210ea10e54b3e3b09735c6cb9e57c1";
    sha256 = "sha256-bwzEO8exoBwa19q+jnYjHkaamGl2mhfukIEhDfUCRGI=";
  };

  installPhase = ''
    mkdir -p $out/themes
    cp -r themes/* $out/themes
  '';
}
