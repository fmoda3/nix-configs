{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-08-24";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "055f46dc4558e0c4c3b32da8b3df6a53ecacd6cb";
    sha256 = "sha256-Iz7Z0+SYShr/Ucw89NNW2Oy3k2GoGvr3atGxaK9zd7Y=";
  };

  npmDepsHash = "sha256-49BUnIE/jK1wnBYEAOsyCvMb6h82uNiJMnY7xTQRUdc=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
