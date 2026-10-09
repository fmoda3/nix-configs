{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-10-09";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "7edc1eaa8412d3344dbdfcf10b2e40c6d7a9baa3";
    sha256 = "sha256-p666agRYi9PhhTrhmFHYViJKbIWLcfi/G+9YPgy7y+M=";
  };

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-QNn8JSPSTpbQ2FM4hyhYUsTPb9qW0Rr0D8DQ8/5r84w=";
}
