{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-mcp-adapter";
  version = "2026-09-30";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-mcp-adapter";
    rev = "e12ef733fd876ea197728fcd5e6be3f9d2aacff1";
    sha256 = "sha256-TKo577jSLCPXkmenC+McFEZohtfGWnFTE57MH5um6+c=";
  };

  # Upstream ships its own package-lock.json, but the nested @earendil-works/*
  # dev dependencies are missing integrity fields, which makes prefetch-npm-deps
  # panic ("non-git dependencies should have associated integrity"). Inject the
  # published sha512 integrity hashes.
  postPatch = ''
    addIntegrity() {
      local package="$1"
      local integrity="$2"
      local resolved="https://registry.npmjs.org/@earendil-works/$package/-/$package-0.99.1.tgz"
      local missingIntegrity
      local withIntegrity
      missingIntegrity=$(printf '"resolved": "%s",\n      "dev": true,' "$resolved")
      withIntegrity=$(printf '"resolved": "%s",\n      "integrity": "%s",\n      "dev": true,' "$resolved" "$integrity")

      substituteInPlace package-lock.json \
        --replace-fail "$missingIntegrity" "$withIntegrity"
    }

    addIntegrity chord "sha512-4xyn0IBzJ+Xu/iOGi2hjXJGAR61QEhEWZsIqTDqr+GmItdquYwBO5jYFnqGiBaTqlY12/EpM7QHoEKSHbyvOug=="
    addIntegrity pi-agent-core "sha512-zywvWnj5FujeuFI/x/CJHwwxhcLIQgjqseTA+bQgX4O8gJTcgjRd/I8SZnQDqJvxC9QcV12ujiGLviv6EgwcCg=="
    addIntegrity pi-ai "sha512-4nV9JKc94iPX8bwdGPc2nTuVPKIPsffhnp3WoN9NYCNqbtoOF8LhYcIs/+Sn/alroqJK/5QRu6/Z6Ck+n0hyBA=="
    addIntegrity pi-codemode "sha512-oh8TMsBI3SWTN3xTQtX8u5n+BKhnVXcFagroWumfn6/WWfBnDYL/LmeQtjLb83WRTb9rcu+ZdK8rFa4vggvCJg=="
    addIntegrity pi-mcp "sha512-YCFGPkmDzLwQuIzwfbP6Vuk/g/ukKpZhwTpbcfzomuI1Fkiu6hHRkOGwAqsO3G8cTkZWkM8vmOkFJjStQNC4qA=="
    addIntegrity pi-telemetry "sha512-9PBPjGk+TXRtuMianpqBbHBpYpyKusESF6rwdmgD0WTZSTUQXhcKEO0hAINRLuSwy4V7yPvXV+EVV0ONY7mbpQ=="
    addIntegrity pi-tui "sha512-gZp0Guat96Fr1AuC/xqVz5B2lulZakp/PxD1lXx3lSgBdjiqmwYhJbcQ0HRrGAfy0WtMGn9b05RJr5qJf7oIuw=="
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-WgF4pBrMvv5/Hyof3WCZSuVOCGf+OK6Of0b0qzex2wU=";
}
