{ buildPiExtension }:

buildPiExtension {
  pname = "pi-toast";
  version = "2026-07-01";

  src = fetchGit {
    url = "git@github.toasttab.com:toasttab/pi-toast.git";
    rev = "d2d0fb13349a83d9a28b71184c2d55ecce735af8";
    narHash = "sha256-2VHMo7kkJzmP1GOrmYpzrUj7qw+6Il1XFiT07T1fnXs=";
  };

  postPatch = ''
    substituteInPlace package-lock.json \
      --replace-fail $'"node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-agent-core": {\n      "version": "0.80.3",\n      "resolved": "https://registry.npmjs.org/@earendil-works/pi-agent-core/-/pi-agent-core-0.80.3.tgz",\n      "license": "MIT",\n      "peer": true,' \
                     $'"node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-agent-core": {\n      "version": "0.80.3",\n      "resolved": "https://registry.npmjs.org/@earendil-works/pi-agent-core/-/pi-agent-core-0.80.3.tgz",\n      "integrity": "sha512-3qw0/GeRQBU/nlGjDe5Yb7ePKTmoxefx2YxyKMFAviFUMXpFexBG/hS7mBtwFahFvzrrTPPoRT6sFIDjwoDWPQ==",\n      "license": "MIT",\n      "peer": true,' \
      --replace-fail $'"node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-ai": {\n      "version": "0.80.3",\n      "resolved": "https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-0.80.3.tgz",\n      "license": "MIT",\n      "peer": true,' \
                     $'"node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-ai": {\n      "version": "0.80.3",\n      "resolved": "https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-0.80.3.tgz",\n      "integrity": "sha512-jPZLMeGL5kkMSEAwAklfXTMHqZvfhsJtCCpKGIr5Duk7mc0n4skjB1dugk7y0z3z8ZHIUCmPAWHdyDqgUz5vdA==",\n      "license": "MIT",\n      "peer": true,' \
      --replace-fail $'"node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-tui": {\n      "version": "0.80.3",\n      "resolved": "https://registry.npmjs.org/@earendil-works/pi-tui/-/pi-tui-0.80.3.tgz",\n      "license": "MIT",\n      "peer": true,' \
                     $'"node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-tui": {\n      "version": "0.80.3",\n      "resolved": "https://registry.npmjs.org/@earendil-works/pi-tui/-/pi-tui-0.80.3.tgz",\n      "integrity": "sha512-2BJI6qwRQfnM0Q7seL1+SbacU/jRRjBnN7Hu3n9BjAn7/s5FaBNnvdD1qBQYRsFTHfjqMaDsjYqanPyqwXj99w==",\n      "license": "MIT",\n      "peer": true,'
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-zYk00hhMcJeOFbv7qwzYMcHQ18CpTRuKwPiZHefoQZU=";

  prunePaths = [
    ".github"
    "test"
  ];
}
