{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-prompt-template-model";
  version = "2026-07-01";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-prompt-template-model";
    rev = "ab60d66af05c4a2196111dc7a2c468b1566481e1";
    hash = "sha256-+TDe46xLCDq2M7H9b4BTNK3ErWLR4pjDteyz+NsCBDo=";
  };

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-qIOSIt977vyPKLtP8JrLkaOq/1nGBJAvJgYy96gIxIE=";

  prunePaths = [
    ".github"
    "test"
  ];
}
