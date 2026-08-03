{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-08-02";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "bf9e683cfa255382817f0893405c36577344bbd0";
    sha256 = "sha256-cHrMtLq6HYCp51iIuvvyYxOQoF5i0o7vuFk0u6BrPYs=";
  };

  npmDepsHash = "sha256-MS8MWvOQ/rX1px7952kcNOqZkYdy35/XoSKt6LP8jGY=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
