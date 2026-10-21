{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-10-21";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "80f8f79d51ee8075fd39baf7fe8ff36b43c3a790";
    sha256 = "sha256-/XjtoCIQu1c0DwOM+aeWWBmyk7JFuQWB10o9RLJk/kU=";
  };

  npmDepsHash = "sha256-0eDwWHfFmxouY8uf0VURFYn6dWbDnh6x1Hj8AaARCvc=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
