{ stdenv
, fetchFromGitHub
}:
stdenv.mkDerivation {
  pname = "catppuccin-yazi";
  version = "1.0";

  src = fetchFromGitHub {
    owner = "catppuccin";
    repo = "yazi";
    rev = "043ffae14e7f7fcc136636d5f2c617b5bc2f5e31";
    sha256 = "sha256-zkL46h1+U9ThD4xXkv1uuddrlQviEQD3wNZFRgv7M8Y=";
  };

  installPhase = ''
    mkdir -p $out/themes
    cp -r themes/* $out/themes
  '';
}
