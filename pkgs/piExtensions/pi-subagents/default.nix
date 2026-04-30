{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-04-30";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "c0396e2055cccc23494c62ca6ee2ae4b15f1d6fe";
    sha256 = "sha256-YRo8/t8aiddT+RPx522cheSHvJCZS9K4uQ5TkX3amm8=";
  };

  prunePaths = [ ".github" ];
}
