{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-08-07";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "7cf138812bf1cd379331487edf6518b757bb2c1f";
    sha256 = "sha256-i2FQobA5RpCsz+x1yOr9OkKsISke+RXf2cmQWR3+YhE=";
  };

  npmDepsHash = "sha256-hA3fM5gdi0+SHph+8n8/5TWnb4m++4fsbVLkvhUiaJE=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
