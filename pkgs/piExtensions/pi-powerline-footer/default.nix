{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-powerline-footer";
  version = "2026-03-12";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-powerline-footer";
    rev = "a35153e35d9588aa3c23985f8425e5c80b01b46c";
    sha256 = "sha256-CvDU324IYcyBcSMWkbjS+G3YfsXslpNrAzYXyxZSI+M=";
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
