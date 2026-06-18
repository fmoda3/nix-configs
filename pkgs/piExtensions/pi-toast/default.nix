{ buildPiExtension }:

buildPiExtension {
  pname = "pi-toast";
  version = "2026-06-17";

  src = fetchGit {
    url = "git@github.toasttab.com:toasttab/pi-toast.git";
    rev = "efcb89592dc8259cee6d19df44318cac957386f6";
    narHash = "sha256-rwb0/zWEBUXYJXBxxjWK20b2MZN9YJaJ27vo6JY6SzQ=";
  };

  postPatch = ''
    substituteInPlace package-lock.json \
      --replace-fail $'"node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-agent-core": {\n      "version": "0.78.1",\n      "resolved": "https://registry.npmjs.org/@earendil-works/pi-agent-core/-/pi-agent-core-0.78.1.tgz",\n      "license": "MIT",\n      "peer": true,' \
                     $'"node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-agent-core": {\n      "version": "0.78.1",\n      "resolved": "https://registry.npmjs.org/@earendil-works/pi-agent-core/-/pi-agent-core-0.78.1.tgz",\n      "integrity": "sha512-oPwVRkkAvyKPWyM7E4k+EaTNmynbYn7ZLG/LBh9BUnMNb2gvpMp+VQ420R6JCJ20uogSqrHnWTyosSa/rU8lVw==",\n      "license": "MIT",\n      "peer": true,' \
      --replace-fail $'"node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-ai": {\n      "version": "0.78.1",\n      "resolved": "https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-0.78.1.tgz",\n      "license": "MIT",\n      "peer": true,' \
                     $'"node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-ai": {\n      "version": "0.78.1",\n      "resolved": "https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-0.78.1.tgz",\n      "integrity": "sha512-CM2pkTs1iupG/maw381lC9Q/Y/aQaMGK7GILc28ttImD0ci3LDwKroDsGkWbly5JIy3iqxdRxB9JlG7vvzCzTg==",\n      "license": "MIT",\n      "peer": true,' \
      --replace-fail $'"node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-tui": {\n      "version": "0.78.1",\n      "resolved": "https://registry.npmjs.org/@earendil-works/pi-tui/-/pi-tui-0.78.1.tgz",\n      "license": "MIT",\n      "peer": true,' \
                     $'"node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-tui": {\n      "version": "0.78.1",\n      "resolved": "https://registry.npmjs.org/@earendil-works/pi-tui/-/pi-tui-0.78.1.tgz",\n      "integrity": "sha512-07GVQo/38a0yvIPlWDr3RJn1B8gk3ZuIX9h2oIQ+Biyu3JN0KppWmgWHfaWRydQgse5JtC++KDw5MWaIRnV0mw==",\n      "license": "MIT",\n      "peer": true,'
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-7aezS7gdxWryBc6FOWbYFQwIahBNe6pG3a50I6kNJ/Q=";

  prunePaths = [
    ".github"
    "test"
  ];
}
