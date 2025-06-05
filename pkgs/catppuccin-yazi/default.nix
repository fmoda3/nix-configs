{ stdenv
, fetchFromGitHub
}:
stdenv.mkDerivation {
  pname = "catppuccin-yazi";
  version = "1.0";

  src = fetchFromGitHub {
    owner = "catppuccin";
    repo = "yazi";
    rev = "fca8e93e0a408671fa54cc0cb103e76b85e8c011";
    sha256 = "sha256-ILaPj84ZlNc6MBwrpwBDNhGhXge9mPse4FYdSMU4eO8=";
  };

  installPhase = ''
    mkdir -p $out/themes
    cp -r themes/* $out/themes
  '';
}
