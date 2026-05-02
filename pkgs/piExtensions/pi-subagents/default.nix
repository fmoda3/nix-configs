{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-05-02";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "1fd371d2a068458741a15507edc6cd49a9807486";
    sha256 = "sha256-YW8Wvc7+3MeKvE4kqAG/cuVIudxWBWcn80qY/yR9Nys=";
  };

  prunePaths = [ ".github" ];
}
