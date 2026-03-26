{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "catppuccin-atuin";
  version = "2026-03-02";

  src = fetchFromGitHub {
    owner = "catppuccin";
    repo = "atuin";
    rev = "68aa64b77573c235044b614e752a781701af4eec";
    sha256 = "sha256-4V9Rz37PlBLB1E3JVVYzrJwe9XXlKAFAO5gxWW/cTCw=";
  };

  installPhase = ''
    mkdir -p $out/themes
    cp -r themes/* $out/themes
  '';
}
