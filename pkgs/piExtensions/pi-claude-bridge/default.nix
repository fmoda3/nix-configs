{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-claude-bridge";
  version = "0.10.0";

  src = fetchFromGitHub {
    owner = "elidickinson";
    repo = "pi-claude-bridge";
    rev = "2ee88826d3df5b9dcdb081ea3540f4aef631038c";
    sha256 = "sha256-A1hGf/DrZ3iQvk7K73kQ/NoouqfbGbwNO1a3fsQcJog=";
  };

  npmDepsHash = "sha256-OQk1NkHRTDNti0xSaxrJzH/rg4WgejEnWhXaLkY3Lfc=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
