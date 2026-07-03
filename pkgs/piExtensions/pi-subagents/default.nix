{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-07-03";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "b0a65aeec322e5f24c14f136ade3421007a90c29";
    sha256 = "sha256-yNnpzjj2ZiYdZQuZ8mzVIO1YSMXVMSkqdOsD1wbcW7E=";
  };

  prunePaths = [ ".github" ];
}
