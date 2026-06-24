{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-tasks";
  version = "2026-06-24";

  src = fetchFromGitHub {
    owner = "tintinweb";
    repo = "pi-tasks";
    rev = "d478be2f07d56c7af126876eb0a53a36f27bbf0a";
    sha256 = "sha256-HpGF5iFLMc4JfTZCGZ/2SLUdcPcju3htSTTjrzVsC30=";
  };

  postPatch = ''
    substituteInPlace package-lock.json \
      --replace-fail $'"node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-agent-core": {\n      "version": "0.78.0",\n      "resolved": "https://registry.npmjs.org/@earendil-works/pi-agent-core/-/pi-agent-core-0.78.0.tgz",\n      "license": "MIT",' $'"node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-agent-core": {\n      "version": "0.78.0",\n      "resolved": "https://registry.npmjs.org/@earendil-works/pi-agent-core/-/pi-agent-core-0.78.0.tgz",\n      "integrity": "sha512-xhWd59Qzd8yO88gYQw2S4dEQstJJEiUtxRP01//YzVJ61jCtUASMfcyAmYhgGYR4Onp7GmwEAbBBGOiV6Iwk9g==",\n      "license": "MIT",' \
      --replace-fail $'"node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-ai": {\n      "version": "0.78.0",\n      "resolved": "https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-0.78.0.tgz",\n      "license": "MIT",' $'"node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-ai": {\n      "version": "0.78.0",\n      "resolved": "https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-0.78.0.tgz",\n      "integrity": "sha512-q0hUrvT6ngT6cgBX0oIbzfQfmzztgdkZobP8OTL+sCOOBlnG6+1YRt8g7zO9CC/4NdeYEqa7uGqWdQhH0fjCLA==",\n      "license": "MIT",' \
      --replace-fail $'"node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-tui": {\n      "version": "0.78.0",\n      "resolved": "https://registry.npmjs.org/@earendil-works/pi-tui/-/pi-tui-0.78.0.tgz",\n      "license": "MIT",' $'"node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-tui": {\n      "version": "0.78.0",\n      "resolved": "https://registry.npmjs.org/@earendil-works/pi-tui/-/pi-tui-0.78.0.tgz",\n      "integrity": "sha512-3a705FnsVVUhAyceShNB3kS2rpxcxLcx+hqB0u6MMMpHwQGbW+m++MqA6r7eOzq/8FLx5e3vDh38h/SVTk2qzw==",\n      "license": "MIT",'
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-XorOKfttMqzyE1g1nDzB8JEjipWCLYS0PrtbyD/iFM0=";

  prunePaths = [
    ".github"
    "test"
    "media"
  ];
}
