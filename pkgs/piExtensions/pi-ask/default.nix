{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-ask";
  version = "2026-05-22";

  src = fetchFromGitHub {
    owner = "eko24ive";
    repo = "pi-ask";
    rev = "77228ca5668a6f14f97438dac888a2917ad37edd";
    sha256 = "sha256-FeFXZ5g+/V3kBvHwgNkgtF4Qp/27rw5d/Nb5s7C+n+s=";
  };

  prunePaths = [ ".github" ];
}
