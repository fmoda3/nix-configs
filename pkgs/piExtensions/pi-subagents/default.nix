{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-08-14";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "30c6080ae1e4b5e66758033ad7896d9259325d75";
    sha256 = "sha256-r3Ye3kRQ50c+KXQ659xv3gqJS+ZnbYFQ9m1b44YH8o0=";
  };

  npmDepsHash = "sha256-VeUptKmEiwuMyhAozpoIx8SACsJMjk7EFNcE8EG8lhU=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
