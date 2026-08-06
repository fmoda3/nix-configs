{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-mcp-adapter";
  version = "2026-08-06";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-mcp-adapter";
    rev = "08fe82be1d55036d3960c4bb3fa77ed8707f2bca";
    sha256 = "sha256-VMmCkOHLk7Bu2ROiZuSwF3c1IspgFjjwxohmoDxyaYk=";
  };

  # Upstream ships its own package-lock.json, but the nested @earendil-works/*
  # dev dependencies are missing integrity fields, which makes prefetch-npm-deps
  # panic ("non-git dependencies should have associated integrity"). Inject the
  # published sha512 integrity hashes so the lock can be used as-is.
  postPatch = ''
    substituteInPlace package-lock.json \
      --replace-fail $'"resolved": "https://registry.npmjs.org/@earendil-works/pi-agent-core/-/pi-agent-core-0.79.10.tgz",\n      "dev": true,' $'"resolved": "https://registry.npmjs.org/@earendil-works/pi-agent-core/-/pi-agent-core-0.79.10.tgz",\n      "integrity": "sha512-XKxgdjhcPuyjrthCOFSgfzT3xZ1uBrJ1IMVDxci1to6hIN6BIg9J5iY8q0pGXK1DLgATLP23da+1UyZLwA360Q==",\n      "dev": true,' \
      --replace-fail $'"resolved": "https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-0.79.10.tgz",\n      "dev": true,' $'"resolved": "https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-0.79.10.tgz",\n      "integrity": "sha512-9jR23tOl0BIUdQMn70Gr72xYBpM7Xgl9Lyv7gAnU1USfkNRuYG/f/edLl+n/Dp/RafDW3JI4DF7y/GhgkORuew==",\n      "dev": true,' \
      --replace-fail $'"resolved": "https://registry.npmjs.org/@earendil-works/pi-tui/-/pi-tui-0.79.10.tgz",\n      "dev": true,' $'"resolved": "https://registry.npmjs.org/@earendil-works/pi-tui/-/pi-tui-0.79.10.tgz",\n      "integrity": "sha512-FUVOjDn1DVwM1uHD5MNYboXQrXjIDbSt+BQ3py7nQWCY62tKfxgiM1OBMxTcwRWLfSdZHUPpV0hm1loIdUJnPw==",\n      "dev": true,'
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-edqN+71gEoXamNXPW60sVrxjHaDnDX6pOwv0aYpDfHQ=";
}
