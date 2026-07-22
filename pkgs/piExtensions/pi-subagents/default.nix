{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-07-21";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "e658b40fe72d599df231b5d59ffec40d66f576fa";
    sha256 = "sha256-6BHPrSjyfJwAyjxJRBgM/0HI9bhJ+rYclWMrUhiPOF4=";
  };

  npmDepsHash = "sha256-0Vv38GKyCJRGmkN10ph0Tpxl9Fese5zzZqcoFVJ+IQU=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
