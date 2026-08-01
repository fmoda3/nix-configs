{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-08-01";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "d4d2ab706b612ccd173caad2bc202eef07e7eda3";
    sha256 = "sha256-LNm4h9OxoljQNXZKmg+P3MUHEWDO6H2x0qMx/gHQwkY=";
  };

  npmDepsHash = "sha256-MS8MWvOQ/rX1px7952kcNOqZkYdy35/XoSKt6LP8jGY=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
