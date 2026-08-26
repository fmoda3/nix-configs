{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-08-26";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "85ba7b13002f5b1e9ba4015b8c4bed169f1d805a";
    sha256 = "sha256-i5UeUXox8/ppau+azB4azfebc7YEj3z8atQ8wuqlpbI=";
  };

  npmDepsHash = "sha256-3F7yuZ5JSCGusVwmGqWriicHfUPxAKM5J2ePWnR6TYg=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
