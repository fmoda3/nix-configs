{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-intercom";
  version = "0.6.0";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-intercom";
    rev = "5caa4aa1bd060cf0aebbf1a5dfbb1abb6e23e457";
    sha256 = "sha256-cYh7zsSbDqsq5JpNQbAZFGS/beRN7oh/KuTN3QQZn34=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-phUBANqAAiYzjOAfiG/CpMLVG3ORAJ5SYt5QIAbyMyI=";
}
