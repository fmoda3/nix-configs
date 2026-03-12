{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-powerline-footer";
  version = "0.4.0";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-powerline-footer";
    rev = "c8e82ebb9d25ac554865802e4f902528721754bb";
    sha256 = "sha256-cr/4GD3EmIGLckQsthfaikLmo8LZE1/o+8nqQAGcehQ=";
  };

  # fix crash until https://github.com/nicobailon/pi-powerline-footer/issues/4 is fixed
  postPatch = ''
    substituteInPlace presets.ts \
      --replace-fail 'tokens: "primary"' 'tokens: "muted"'
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github

    runHook postInstall
  '';
}
