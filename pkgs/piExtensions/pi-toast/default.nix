{ buildPiExtension }:

buildPiExtension {
  pname = "pi-toast";
  version = "2026-06-25";

  src = fetchGit {
    url = "git@github.toasttab.com:toasttab/pi-toast.git";
    rev = "97e9238e02b6c1fbd5ed1b884289da011d343cef";
    narHash = "sha256-T4mFHtcXwsWvjs2GJALtE6/hIBduGSgsazgkn+RsH88=";
  };

  postPatch = ''
    substituteInPlace package-lock.json \
      --replace-fail $'"node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-agent-core": {\n      "version": "0.80.1",\n      "resolved": "https://registry.npmjs.org/@earendil-works/pi-agent-core/-/pi-agent-core-0.80.1.tgz",\n      "license": "MIT",\n      "peer": true,' \
                     $'"node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-agent-core": {\n      "version": "0.80.1",\n      "resolved": "https://registry.npmjs.org/@earendil-works/pi-agent-core/-/pi-agent-core-0.80.1.tgz",\n      "integrity": "sha512-/Y4XzinEIQekXRjMxtYy2QJt6y43Gw+7itAvsA8TNCuUrYMBI6WvZjlMMcYsjK+Oyt919noN0EsT9/Xd3D0ziw==",\n      "license": "MIT",\n      "peer": true,' \
      --replace-fail $'"node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-ai": {\n      "version": "0.80.1",\n      "resolved": "https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-0.80.1.tgz",\n      "license": "MIT",\n      "peer": true,' \
                     $'"node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-ai": {\n      "version": "0.80.1",\n      "resolved": "https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-0.80.1.tgz",\n      "integrity": "sha512-qsHmuoBRu7a6rkOis/Elwl8jEhA9T884H/mXMP3tbz1slEBI+dHaY3zJ0nlEqUl+jcTz1FJNdgOVLG4sQHOPXQ==",\n      "license": "MIT",\n      "peer": true,' \
      --replace-fail $'"node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-tui": {\n      "version": "0.80.1",\n      "resolved": "https://registry.npmjs.org/@earendil-works/pi-tui/-/pi-tui-0.80.1.tgz",\n      "license": "MIT",\n      "peer": true,' \
                     $'"node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-tui": {\n      "version": "0.80.1",\n      "resolved": "https://registry.npmjs.org/@earendil-works/pi-tui/-/pi-tui-0.80.1.tgz",\n      "integrity": "sha512-lmXGOiFv5KMati4VfdQt1L/7/m4yiJ8Xqm96COgkURPXhWqRFOMboqDJzyLMyKUpDnyQPS0OenVmHMn/uys3Lw==",\n      "license": "MIT",\n      "peer": true,'
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-6VwCB5JdQK0BAV7kFJgk3NpSKAsCc1ozmZ7GXP0OE4o=";

  prunePaths = [
    ".github"
    "test"
  ];
}
