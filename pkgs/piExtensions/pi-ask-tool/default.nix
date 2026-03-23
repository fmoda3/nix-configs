{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-ask-tool";
  version = "2026-03-23";

  src = fetchFromGitHub {
    owner = "devkade";
    repo = "pi-ask-tool";
    rev = "fde70011e75ca60baff37f335f824b6cf26c9fac";
    sha256 = "sha256-q8Wsw1ysVMMMeDHsstIirbeb6ST2K8+dK5IG7ukKXFA=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github

    runHook postInstall
  '';
}
