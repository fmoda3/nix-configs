{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-08-05";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "a6a60d7fc4476baf40847cefd7aaaef51a91f61f";
    sha256 = "sha256-tBeSmhLONN/pzLUf/3CGGqb1IMjlEH9zfp+HCpQZZ6w=";
  };

  npmDepsHash = "sha256-ZRKaAVB7K4rbfH4ZDjxE7pzZqQvuXdCUbvrdVYZGqn8=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
