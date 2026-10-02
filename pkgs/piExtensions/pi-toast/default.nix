{ buildPiExtension }:

buildPiExtension {
  pname = "pi-toast";
  version = "2026-10-02";

  src = fetchGit {
    url = "git@github.toasttab.com:toasttab/pi-toast.git";
    rev = "b838d82b5ba48b0b213dceae3b5c6bcf89e98b72";
    ref = "main";
    narHash = "sha256-27mgLYNDXf1KGwWoCTpBVkB9a6OcfGEQvaHLUxh17CU=";
  };

  postPatch = ''
    addIntegrity() {
      local package="$1"
      local integrity="$2"
      local resolved="https://registry.npmjs.org/@earendil-works/$package/-/$package-0.99.1.tgz"
      local missingIntegrity
      local withIntegrity
      missingIntegrity=$(printf '"resolved": "%s",\n      "license": "MIT",\n      "peer": true,' "$resolved")
      withIntegrity=$(printf '"resolved": "%s",\n      "integrity": "%s",\n      "license": "MIT",\n      "peer": true,' "$resolved" "$integrity")

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
  npmDepsHash = "sha256-wvict+72W2wfhzzXRenjVk/R8m+R8/HlDO2HaQ+po28=";

  prunePaths = [
    ".github"
    "test"
  ];
}
