{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-11-20";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "fb7ce3ce7524e35b241a2aa6ae13cd574dd1c593";
    sha256 = "sha256-6XHZ/+KPcx2AcVB2TY9V49Ticw5NbHU4RML7lJ9OsdU=";
  };

  npmDepsHash = "sha256-Rx+IzIc1+iv5RoUfc23KmF884D7bd+522qr9I28gu6Q=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
