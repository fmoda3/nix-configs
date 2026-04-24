{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-ask-tool";
  version = "2026-03-29";

  src = fetchFromGitHub {
    owner = "devkade";
    repo = "pi-ask-tool";
    rev = "d4e2c0c1a28afd5440c43771a9efb8b5aa190529";
    sha256 = "sha256-ETZ5OmD2n9Uq7Z0eJpC3FYSguiLiPINXUXsLKJCdTKY=";
  };

  prunePaths = [ ".github" ];
}
