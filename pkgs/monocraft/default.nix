{ lib, fetchurl }:

let
  version = "1.2";
in
fetchurl rec {
  name = "monocraft-${version}";

  url = "https://github.com/IdreesInc/Monocraft/releases/download/v${version}/Monocraft.otf";

  downloadToTemp = true;

  recursiveHash = true;

  sha256 = "sha256-o0nWbXvUOdfDI8ZydYIs7ygaE3ig+ksm8J/xZ38Gslk=";

  postFetch = ''
    mkdir -p $out/share/fonts/opentype
    mv $downloadedFile Monocraft.otf
    install Monocraft.otf $out/share/fonts/opentype
  '';

  meta = with lib; {
    description = "The font for developers who like Minecraft a bit too much";
    homepage = "https://github.com/IdreesInc/Monocraft";
    license = licenses.ofl;
    platforms = platforms.all;
    maintainers = with maintainers; [ ];
  };
}
