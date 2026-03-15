{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-powerline-footer";
  version = "2026-03-15";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-powerline-footer";
    rev = "4b6cd01bc73e785b0d1c19b34317593a2a1905f7";
    sha256 = "sha256-d2QHF7ViymHVUZ2fINSRvI7Dl2QgTeKE91gAp7oC6m0=";
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
