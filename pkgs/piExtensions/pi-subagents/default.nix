{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-05-02";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "bc26a571c2c36025e3dc48ebebf7b91c0c096305";
    sha256 = "sha256-Y5cUwjDbKIGBRSnGJvtsfM+inzS4AaGong3yPcV+7FM=";
  };

  prunePaths = [ ".github" ];
}
