{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-tasks";
  version = "2026-08-16";

  src = fetchFromGitHub {
    owner = "tintinweb";
    repo = "pi-tasks";
    rev = "ef37c25de14b3f7d0c09010b721e3419dc557b10";
    sha256 = "sha256-KcOqt8DPUHaUZX2vxoKINFDCLFZD1SmHZw0Lpt1Nk/4=";
  };

  postPatch = ''
    addIntegrity() {
      local package="$1"
      local integrity="$2"
      local resolved="https://registry.npmjs.org/@earendil-works/$package/-/$package-0.84.2.tgz"
      local missingIntegrity
      local withIntegrity
      missingIntegrity=$(printf '"resolved": "%s",\n      "dev": true,' "$resolved")
      withIntegrity=$(printf '"resolved": "%s",\n      "integrity": "%s",\n      "dev": true,' "$resolved" "$integrity")

      substituteInPlace package-lock.json \
        --replace-fail "$missingIntegrity" "$withIntegrity"
    }

    addIntegrity pi-agent-core "sha512-8Pn3wSCxj0cfo5I6jxQYVB/3uuQRmHhAlEclyjqpOuMEdQMIODHizRogv56FLdbU+dTiGnybeHQ2N+sV1/L2YA=="
    addIntegrity pi-ai "sha512-6MzsrYIYNVlE7SfpbL2yYb67Qo58p/7Q+xWG1RZvoX1P80aRCHSod2/13aFpxkow1lPO2LEh3c495J0Gwmyjig=="
    addIntegrity pi-client "sha512-/RFSPhD/bZbpOp1oJj+UneSUFSgZhWxzcSENUY+8+8xhoBrWXMYI2t77XNx4Yf+c8YK2qTHquForhNcelYpXvg=="
    addIntegrity pi-protocol "sha512-jbBh03fkeckWEroHpcZBr4w5/Ibat8WwdXFlXHivYQImrQNFtLpDeL0t1cku4hmK0q3pceIRQHkw4fwbM4YILQ=="
    addIntegrity pi-telemetry "sha512-wg5caea7uIv1BHRBm2Y116RvFG4oSAiP5qk9tA2463PDGIr4K8M1Ceyyg5DOpF/shUUl0gk826yQJAeAcHYB9g=="
    addIntegrity pi-tui "sha512-ds2TLihOnM5sLJB3VpXV6y0uR5efVuHf4MN7yDpsty6hA2DUO/EDVzjp/0od0G2JslzVLMjT8T8zavtxVb+qbg=="
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-TE/Ku1N+z8TMm7HO1f2QexWn8LzgA8UkSwYjiJ3ji0k=";

  prunePaths = [
    ".github"
    "test"
    "media"
  ];
}
