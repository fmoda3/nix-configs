{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-powerline-footer";
  version = "0.2.24";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-powerline-footer";
    rev = "ced10bcd14273c99637c2474840286c173acc1d7";
    sha256 = "sha256-4nxY66Xx38RVhN1LUVMqpwwruwVpOCNhi+tGYRL5fkM=";
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
