{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-mcp-adapter";
  version = "2026-09-23";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-mcp-adapter";
    rev = "28049dee20cd0ee809cf5a78442cf35dfa36659c";
    sha256 = "sha256-fZ6sAJhNjSMz/KVsuuNtjkomkI5rQ0qlWMpvFVPinEc=";
  };

  # Upstream ships its own package-lock.json, but the nested @earendil-works/*
  # dev dependencies are missing integrity fields, which makes prefetch-npm-deps
  # panic ("non-git dependencies should have associated integrity"). Inject the
  # published sha512 integrity hashes.
  postPatch = ''
    substituteInPlace package-lock.json \
      --replace-fail $'"resolved": "https://registry.npmjs.org/@earendil-works/chord/-/chord-0.87.0.tgz",\n      "dev": true,' $'"resolved": "https://registry.npmjs.org/@earendil-works/chord/-/chord-0.87.0.tgz",\n      "integrity": "sha512-t8QOTf0GTHrsDSfcdtXuA9RCkh6mnR4l25N0SM/sgH7Ih25jH4tGXNbkGs9MWpV5xTu9MRPj4A7Zn1UEwQm9+g==",\n      "dev": true,' \
      --replace-fail $'"resolved": "https://registry.npmjs.org/@earendil-works/pi-agent-core/-/pi-agent-core-0.87.0.tgz",\n      "dev": true,' $'"resolved": "https://registry.npmjs.org/@earendil-works/pi-agent-core/-/pi-agent-core-0.87.0.tgz",\n      "integrity": "sha512-c5b2FMdJ7C++HBa6AyBmusdf96gdgRqpF7J+UCq2yVGB28UETJvJ190HkgDWUaLPnOQQPbanjKMAm/TgRmFE2w==",\n      "dev": true,' \
      --replace-fail $'"resolved": "https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-0.87.0.tgz",\n      "dev": true,' $'"resolved": "https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-0.87.0.tgz",\n      "integrity": "sha512-lbRm+EMY6Jx3l+HLpbqbm9Yrhkc5u7EffLk2id+zJQEoBuR5I+tijGiZU8zlnuuCclmQOgH0PVjL9PLbeqJ9MQ==",\n      "dev": true,' \
      --replace-fail $'"resolved": "https://registry.npmjs.org/@earendil-works/pi-telemetry/-/pi-telemetry-0.87.0.tgz",\n      "dev": true,' $'"resolved": "https://registry.npmjs.org/@earendil-works/pi-telemetry/-/pi-telemetry-0.87.0.tgz",\n      "integrity": "sha512-IEUMnV6mgHyOMfAxa4CKXoBKKfHM8KxNjbXWM4Bps/iLJcFMf8hQsEZ+95VnVTc7C0cU77Rmdxt773C35jb5AA==",\n      "dev": true,' \
      --replace-fail $'"resolved": "https://registry.npmjs.org/@earendil-works/pi-tui/-/pi-tui-0.87.0.tgz",\n      "dev": true,' $'"resolved": "https://registry.npmjs.org/@earendil-works/pi-tui/-/pi-tui-0.87.0.tgz",\n      "integrity": "sha512-7gTC0XOgQfVWg4yGxwHINBpCnGl9p4KEC7PXIc8gAwc/cyxSW4VuFQrp+r1YD3oM+rBkoepKwAt6w6+VJ7BCaw==",\n      "dev": true,'
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-zGyPa+ANLqS7gCjpOQWN4EACLftyb/rFT1rCfbKHWwg=";
}
