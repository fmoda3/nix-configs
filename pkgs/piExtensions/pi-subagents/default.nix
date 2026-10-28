{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-10-28";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "9295b1f8e4895bce1c169e54a19cb8813b508e53";
    sha256 = "sha256-/BBYJysW/Bcu7FZk4cfdbwGZnuM5pkKYBI899YyZZaA=";
  };

  npmDepsHash = "sha256-TE8Q7Vlk292NEU3InLsFjPweaGO1G0wxYwrxDILCUds=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
