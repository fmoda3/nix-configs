{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-mcp-adapter";
  version = "2026-09-20";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-mcp-adapter";
    rev = "199b4daaf708bd49e0bab9141255c3cb10f50a58";
    sha256 = "sha256-WhTFydQ7TET4IUAbCPKdsSP+RZnfRyJG+ZvEqFjD3E8=";
  };

  # Upstream ships its own package-lock.json, but the nested @earendil-works/*
  # dev dependencies are missing integrity fields, which makes prefetch-npm-deps
  # panic ("non-git dependencies should have associated integrity"). Inject the
  # published sha512 integrity hashes.
  postPatch = ''
    substituteInPlace package-lock.json \
      --replace-fail $'"resolved": "https://registry.npmjs.org/@earendil-works/chord/-/chord-0.86.0.tgz",\n      "dev": true,' $'"resolved": "https://registry.npmjs.org/@earendil-works/chord/-/chord-0.86.0.tgz",\n      "integrity": "sha512-7EQVCDLLw9GcUpenFZp2zqgkUEmqex/g20ujmgtrkKu//mYhdwHLVM68HCSR4kXPTaP+fiPQp2o/Y3uju6vQ1A==",\n      "dev": true,' \
      --replace-fail $'"resolved": "https://registry.npmjs.org/@earendil-works/pi-agent-core/-/pi-agent-core-0.86.0.tgz",\n      "dev": true,' $'"resolved": "https://registry.npmjs.org/@earendil-works/pi-agent-core/-/pi-agent-core-0.86.0.tgz",\n      "integrity": "sha512-0nGRbPeR2Sx+TXCP+xTNeCoZDegRXshQ9ROWE+wc1XR2l6bARgbelkjiiFwVVJRslbwQa5Hmo/r2JXfAqqkK+A==",\n      "dev": true,' \
      --replace-fail $'"resolved": "https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-0.86.0.tgz",\n      "dev": true,' $'"resolved": "https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-0.86.0.tgz",\n      "integrity": "sha512-7jc4tNTBiJrfg+2/nra6JPz2d3OGiGHDKrSVHpnfvsMgMy0uy4noGb7WidDNcqSEAK1S0kcRRTmpYAK66ZlTSw==",\n      "dev": true,' \
      --replace-fail $'"resolved": "https://registry.npmjs.org/@earendil-works/pi-telemetry/-/pi-telemetry-0.86.0.tgz",\n      "dev": true,' $'"resolved": "https://registry.npmjs.org/@earendil-works/pi-telemetry/-/pi-telemetry-0.86.0.tgz",\n      "integrity": "sha512-vbKNbFpFe6BgeL+N5/EKsZzGa9I2X+pz2icibNNA8JxTlVk2UHup5DXSKYl4yMG5VlXz5aWq4CBJCqb3pRO4fg==",\n      "dev": true,' \
      --replace-fail $'"resolved": "https://registry.npmjs.org/@earendil-works/pi-tui/-/pi-tui-0.86.0.tgz",\n      "dev": true,' $'"resolved": "https://registry.npmjs.org/@earendil-works/pi-tui/-/pi-tui-0.86.0.tgz",\n      "integrity": "sha512-R68axQIwP3yxMJH9Sz8QnzD/4emRiSIsj+k2ahxlJUUJR84bN7YBFul+ZuBvy8Qn+Er4NIoBLTGpPf/4iHMKVA==",\n      "dev": true,'
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-e/RtpBrcLY1u6AakxXfym7HgnzqEaiyuy5/R7WG+Bk0=";
}
