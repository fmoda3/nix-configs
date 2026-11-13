{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-notify";
  version = "2026-11-12";

  src = fetchFromGitHub {
    owner = "ferologics";
    repo = "pi-notify";
    rev = "fa156fec70bee0f11fe3a407d5183ee98b56b783";
    sha256 = "sha256-T+SnYvPcfHEDThPgsX6E/vAxg3ZU0h8vCg9VlITRnHw=";
  };

  prunePaths = [ ".github" ];
}
