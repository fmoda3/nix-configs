{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "catppuccin-fish";
  version = "2025-03-12";

  src = fetchFromGitHub {
    owner = "catppuccin";
    repo = "fish";
    rev = "5fc5ae9c2ec22eb376cb03ce76f0d262a38960f3";
    sha256 = "sha256-3KNWYXfOMzZovdjwjBpjSH8cVlD4CO2QmQcCyQE4Dac=";
  };

  installPhase = ''
    mkdir -p $out/themes
    cp -r themes/* $out/themes
  '';
}
