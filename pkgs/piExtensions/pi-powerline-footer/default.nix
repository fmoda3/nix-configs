{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-powerline-footer";
  version = "2026-03-18";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-powerline-footer";
    rev = "f37425c4d65973d684c49aa64856d150eb7f9188";
    sha256 = "sha256-yeZ3exsyWyULZKxf8+B1xLxDqSfuAnDpdioeknx+zro=";
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
