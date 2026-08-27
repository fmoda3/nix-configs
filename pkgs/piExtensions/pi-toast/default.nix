{ buildPiExtension }:

buildPiExtension {
  pname = "pi-toast";
  version = "2026-08-27";

  src = fetchGit {
    url = "git@github.toasttab.com:toasttab/pi-toast.git";
    rev = "122e087aebb789577c156f361c673a84ac2a717e";
    narHash = "sha256-uiSyaToKYtQcFTtvRBDd3ZCdF2/JsAHgUurOa4IBVhA=";
  };

  postPatch = ''
    substituteInPlace package-lock.json \
      --replace-fail $'"node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-agent-core": {\n      "version": "0.83.0",\n      "resolved": "https://registry.npmjs.org/@earendil-works/pi-agent-core/-/pi-agent-core-0.83.0.tgz",\n      "license": "MIT",\n      "peer": true,' \
                     $'"node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-agent-core": {\n      "version": "0.83.0",\n      "resolved": "https://registry.npmjs.org/@earendil-works/pi-agent-core/-/pi-agent-core-0.83.0.tgz",\n      "integrity": "sha512-RorGp9OH5l3ElpuC5a5ZQ2eWcchZGXflXRzVGkV99y3y6tT+LLNyxoYIdVKvTKWEObwhExeQbTH0fI2tE4iX4g==",\n      "license": "MIT",\n      "peer": true,' \
      --replace-fail $'"node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-ai": {\n      "version": "0.83.0",\n      "resolved": "https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-0.83.0.tgz",\n      "license": "MIT",\n      "peer": true,' \
                     $'"node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-ai": {\n      "version": "0.83.0",\n      "resolved": "https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-0.83.0.tgz",\n      "integrity": "sha512-m3IZD4g3er0V8TC9+Vpgw/sjTKqcJlkcIBy/JvsgRubuuik3tAVzyugUg4rVrShIkkOT69mEd34NEqKUIsl6JQ==",\n      "license": "MIT",\n      "peer": true,' \
      --replace-fail $'"node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-tui": {\n      "version": "0.83.0",\n      "resolved": "https://registry.npmjs.org/@earendil-works/pi-tui/-/pi-tui-0.83.0.tgz",\n      "license": "MIT",\n      "peer": true,' \
                     $'"node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-tui": {\n      "version": "0.83.0",\n      "resolved": "https://registry.npmjs.org/@earendil-works/pi-tui/-/pi-tui-0.83.0.tgz",\n      "integrity": "sha512-IoYrb0rORjELmEpNtoCA/U8je3KopMkRAVJRdSzvXRvgb+Huo1gNh8Q5CSZvNOiYtDxJdj2tYZZHZ4B3+IN3hA==",\n      "license": "MIT",\n      "peer": true,'
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-CK/W5zNtjbTDnH7GnGQL1kXbKwyEbnriEP5yrK+bgW8=";

  prunePaths = [
    ".github"
    "test"
  ];
}
