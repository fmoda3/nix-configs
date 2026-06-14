{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "catppuccin-yazi";
  version = "2026-06-13";

  src = fetchFromGitHub {
    owner = "catppuccin";
    repo = "yazi";
    rev = "baaf5d1c9427b836fbefd126aa855f9eab7a9d0d";
    sha256 = "sha256-L6SApM07CSQk0znEsFP8WaxW+ZHcindXo612r1XcwIg=";
  };

  installPhase = ''
    mkdir -p $out/themes
    cp -r themes/* $out/themes
  '';
}
