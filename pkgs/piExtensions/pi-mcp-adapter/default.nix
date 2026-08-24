{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-mcp-adapter";
  version = "2026-08-23";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-mcp-adapter";
    rev = "6c08147f7a3c6eba670fa8fb73e1fe68a7ab471f";
    sha256 = "sha256-GRbhymazgB4zD1QHp5FuJPiVjlYHsCbKiM3293UnkBc=";
  };

  # Upstream ships its own package-lock.json, but the nested @earendil-works/*
  # dev dependencies are missing integrity fields, which makes prefetch-npm-deps
  # panic ("non-git dependencies should have associated integrity"). Inject the
  # published sha512 integrity hashes so the lock can be used as-is.
  postPatch = ''
    substituteInPlace package-lock.json \
      --replace-fail $'"resolved": "https://registry.npmjs.org/@earendil-works/pi-agent-core/-/pi-agent-core-0.84.1.tgz",\n      "dev": true,' $'"resolved": "https://registry.npmjs.org/@earendil-works/pi-agent-core/-/pi-agent-core-0.84.1.tgz",\n      "integrity": "sha512-evyzXYWCLQGmcaBYHlmSku02r8qoN4SGI60GZABo6iV+H+nqX+P9ud8fEZ4GmRq9mUSREvvfX+w9dA9ThF9C6w==",\n      "dev": true,' \
      --replace-fail $'"resolved": "https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-0.84.1.tgz",\n      "dev": true,' $'"resolved": "https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-0.84.1.tgz",\n      "integrity": "sha512-wMsAdJMxuNri08vLqTyYVI201DQQezGhPSTkzYsHdw5dYX3rCNwEmSvpaAwhi7ELKI/2tE/CEgSWg/6iRxSgdQ==",\n      "dev": true,' \
      --replace-fail $'"resolved": "https://registry.npmjs.org/@earendil-works/pi-client/-/pi-client-0.84.1.tgz",\n      "dev": true,' $'"resolved": "https://registry.npmjs.org/@earendil-works/pi-client/-/pi-client-0.84.1.tgz",\n      "integrity": "sha512-/V5hGHE4Zq+jG0GtwIB9PyBUOGd6gBLZ7lkQYFKchKnxYHeH3rmWC5xw4kpnZKKBuBuFTdLVbU9vEjlAGMMb2A==",\n      "dev": true,' \
      --replace-fail $'"resolved": "https://registry.npmjs.org/@earendil-works/pi-protocol/-/pi-protocol-0.84.1.tgz",\n      "dev": true,' $'"resolved": "https://registry.npmjs.org/@earendil-works/pi-protocol/-/pi-protocol-0.84.1.tgz",\n      "integrity": "sha512-Ox1pciyeSPGEEUcxvR0/dJcrY7C6hrEGA8y71rOsvSIUlXN1Cbp/be/eoL71OGDBk5O97TeQPfWN6Ju/2Ehjww==",\n      "dev": true,' \
      --replace-fail $'"resolved": "https://registry.npmjs.org/@earendil-works/pi-telemetry/-/pi-telemetry-0.84.1.tgz",\n      "dev": true,' $'"resolved": "https://registry.npmjs.org/@earendil-works/pi-telemetry/-/pi-telemetry-0.84.1.tgz",\n      "integrity": "sha512-180/xGJtsq7IoR3p9EKWjRd0e9M4DkxInhlo9xyD7prDC7Qrhqq+nhvwrW0lFjPfXcEI2FSHmGCSyvSJE9GsaQ==",\n      "dev": true,' \
      --replace-fail $'"resolved": "https://registry.npmjs.org/@earendil-works/pi-tui/-/pi-tui-0.84.1.tgz",\n      "dev": true,' $'"resolved": "https://registry.npmjs.org/@earendil-works/pi-tui/-/pi-tui-0.84.1.tgz",\n      "integrity": "sha512-udeXFbgEhJ6JiB0uguwNVNkDy2FENfmtQwPcY+/iJ8GWeq18wkal1tKqa5YyeH0IqtX1vG0cGh8zfSYzyzVuLA==",\n      "dev": true,'
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-Jkl7l5x+Mhbjxca2GBVzTgSKPAM8KI3IjdCHnYtdIlI=";
}
