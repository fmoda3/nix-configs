{ buildPiExtension }:

buildPiExtension {
  pname = "pi-toast";
  version = "2026-06-18";

  src = fetchGit {
    url = "git@github.toasttab.com:toasttab/pi-toast.git";
    rev = "3ca23a2bc6d080ebdfc80fdb5c05741bd5f916a7";
    narHash = "sha256-uZRQYtr8dCPwMMT33ezDGSrmTN6e4UyJBrF40EirYw4=";
  };

  postPatch = ''
    substituteInPlace package-lock.json \
      --replace-fail $'"node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-agent-core": {\n      "version": "0.79.6",\n      "resolved": "https://registry.npmjs.org/@earendil-works/pi-agent-core/-/pi-agent-core-0.79.6.tgz",\n      "license": "MIT",\n      "peer": true,' \
                     $'"node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-agent-core": {\n      "version": "0.79.6",\n      "resolved": "https://registry.npmjs.org/@earendil-works/pi-agent-core/-/pi-agent-core-0.79.6.tgz",\n      "integrity": "sha512-SXZc4rQI+3zgUmAJDbU0GzFEHCPHbhItjN7QLsahj3TKfQAon4guwCqsrwZBLH5lPcub2+evTojPNrPItL62tA==",\n      "license": "MIT",\n      "peer": true,' \
      --replace-fail $'"node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-ai": {\n      "version": "0.79.6",\n      "resolved": "https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-0.79.6.tgz",\n      "license": "MIT",\n      "peer": true,' \
                     $'"node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-ai": {\n      "version": "0.79.6",\n      "resolved": "https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-0.79.6.tgz",\n      "integrity": "sha512-KGepEdgEeWDs7Imwlp96tBsO8TjSIpcDBvazsCDtHRa81+uwJI/YGetTegI52pMlKhVpJFLIGajRi4PCGC5MUg==",\n      "license": "MIT",\n      "peer": true,' \
      --replace-fail $'"node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-tui": {\n      "version": "0.79.6",\n      "resolved": "https://registry.npmjs.org/@earendil-works/pi-tui/-/pi-tui-0.79.6.tgz",\n      "license": "MIT",\n      "peer": true,' \
                     $'"node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-tui": {\n      "version": "0.79.6",\n      "resolved": "https://registry.npmjs.org/@earendil-works/pi-tui/-/pi-tui-0.79.6.tgz",\n      "integrity": "sha512-6JCq780X0UuqvJsUDSJmi4V54ObB8qSwFQiBOI1jhPpC+Ydusd8SEXn2HtyIqve/utMgwcZT9aOyZM72m26A0w==",\n      "license": "MIT",\n      "peer": true,'
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-3HDFTK4DkaGOf5fp/eUaFL5nd/+VM8N83183GZL0kkM=";

  prunePaths = [
    ".github"
    "test"
  ];
}
