{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-08-09";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "67b4f60434ace791efaec1df00d05242f609ce35";
    sha256 = "sha256-f0jA3kIO/OJ/fh3ha+3gW8TEAwns7j8td48oigeka9g=";
  };

  npmDepsHash = "sha256-Sl6+u8E+N+lzWQ7UaBdVT5r6Q2POz9fzKQD+oUhOf9U=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
