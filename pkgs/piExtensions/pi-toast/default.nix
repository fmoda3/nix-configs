{ buildPiExtension }:

buildPiExtension {
  pname = "pi-toast";
  version = "2026-06-23";

  src = fetchGit {
    url = "git@github.toasttab.com:toasttab/pi-toast.git";
    rev = "c8ada514d6ce8b94660b575b301777a858a97f08";
    narHash = "sha256-yEB0QPx21dvdG7usdhPRXXKZFqMZJha7I7+iBvx7j4Q=";
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
