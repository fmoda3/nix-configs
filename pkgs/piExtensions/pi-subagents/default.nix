{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-05-02";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "820a5f1770ccf632b48b26ee5c0b4dd713ded074";
    sha256 = "sha256-x7CU+QBw/ib05x5KO8v87P75N7N46NPmxpTE3thY5zw=";
  };

  prunePaths = [ ".github" ];
}
