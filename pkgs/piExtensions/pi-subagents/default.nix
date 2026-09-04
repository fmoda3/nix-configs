{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-09-04";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "a5f401e8b2bf781a45164885bfdf7626436226f2";
    sha256 = "sha256-Ic+fQmShcuKhvJldYw2zQ4G7d8bCyl425UNzH/IHaTk=";
  };

  npmDepsHash = "sha256-Zet4i/F3aD4MVvNPmGtSazFtC4pNZ5duRqNf8SYXxb0=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
