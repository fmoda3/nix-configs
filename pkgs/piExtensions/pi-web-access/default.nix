{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-10-06";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "f0c0a96a8f19198e767cbec2e447f38779ccca50";
    sha256 = "sha256-iD8q2t6OdbVmV7BKaKn8EhNqCeMnv25WyZNuVOEI9bw=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-RXW3ymqoqq6AnYqmfhgPrMhwB/6jYmaFQdT196vKvf4=";
}
