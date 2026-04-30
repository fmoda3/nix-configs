{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-04-30";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "236cf395baa2a9e934251c4d35835584901c0f4c";
    sha256 = "sha256-1fwRLgsrTZQ5hV/EiOCByN01LAP1IgOl0dVFCngA7DA=";
  };

  prunePaths = [ ".github" ];
}
