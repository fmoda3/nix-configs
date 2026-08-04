{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-mcp-adapter";
  version = "2026-08-04";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-mcp-adapter";
    rev = "f123a7e368ef7caab19a3b3070feef78590a3e2a";
    sha256 = "sha256-wJw+PzvPC/1X8v3ZyrjLqSaPPDH66V9ytsAtydcrU8Y=";
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
  npmDepsHash = "sha256-jaRKSTe0gab4z5p4jnIL2vHed9a2/9o7M14AF2+qdZ8=";
}
