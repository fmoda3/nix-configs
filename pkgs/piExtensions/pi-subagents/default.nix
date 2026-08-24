{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-08-24";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "d3fccd8f52f6e1381daf3953f4073b9162a1d0d5";
    sha256 = "sha256-/ClUYD1LRYJUQiTvGWD/5BcnanJklwr49pOk0cbRc+8=";
  };

  npmDepsHash = "sha256-49BUnIE/jK1wnBYEAOsyCvMb6h82uNiJMnY7xTQRUdc=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
