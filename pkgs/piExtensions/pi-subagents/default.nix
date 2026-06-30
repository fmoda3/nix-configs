{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-06-30";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "21fd014ddda55401728543c5f76840c3785246f7";
    sha256 = "sha256-P/dHAHCa3wt07tDMj5Bns5UfHtD/Acr3lKZlOoN10Tg=";
  };

  prunePaths = [ ".github" ];
}
