{ buildPiExtension }:

buildPiExtension {
  pname = "pi-toast";
  version = "2026-09-22";

  src = fetchGit {
    url = "git@github.toasttab.com:toasttab/pi-toast.git";
    rev = "4a9f56f651a2a735ee2c31188703a48eaccd8f28";
    ref = "main";
    narHash = "sha256-drMFZYZOfNlNjqSL5wyxQmHxy2nnt2Tgk7KXSkQHbQg=";
  };

  postPatch = ''
    addIntegrity() {
      local package="$1"
      local integrity="$2"
      local resolved="https://registry.npmjs.org/@earendil-works/$package/-/$package-0.86.1.tgz"
      local missingIntegrity
      local withIntegrity
      missingIntegrity=$(printf '"resolved": "%s",\n      "license": "MIT",\n      "peer": true,' "$resolved")
      withIntegrity=$(printf '"resolved": "%s",\n      "integrity": "%s",\n      "license": "MIT",\n      "peer": true,' "$resolved" "$integrity")

      substituteInPlace package-lock.json \
        --replace-fail "$missingIntegrity" "$withIntegrity"
    }

    addIntegrity chord "sha512-GzUr5n4tFBHUYxN9CjcRHK8QWo9tbxNrZu6iWPQ+PFiFrLASvSZOKeAVAgh3gHv/t0X5OvUpFlrMQ/nEFfCYpg=="
    addIntegrity pi-agent-core "sha512-8TbBzhYsDeu5V1Zl2NsyrBqJAzX1EiEL3Np3ZjGpy0pSDdGRVOpcyW1qruLqfWmEqGcnxmvgnTMLS/wJNZO2XQ=="
    addIntegrity pi-ai "sha512-1XHhI6D/fyQdsBieHC/E/4zGKVOoGe4yDyX67VXvzoYkFsX/qE7NpZE7E1RC8e6Bz8B9oG/P+MQFXikv2/BGEg=="
    addIntegrity pi-telemetry "sha512-SOcEqOS3oVGgKeahs2jHB906d8hFjuLP+RBee8xKYMRgw5KAeWHNg+YABfL0ALlp3Bt6tW4b632MLghc3vnTog=="
    addIntegrity pi-tui "sha512-FU/zU/zG4RWokcZt+BVXXcieWi5ggvYnWP2kkB5XXjMaHRoy5BDhcZJ9JAnLTN9MwrCRoXgPQxOI0bFqwYeZkQ=="
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-WBjyM95PURiXEf1MFqTFql/Kujo+Ac5vwc8Rp2akppU=";

  prunePaths = [
    ".github"
    "test"
  ];
}
