{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-mcp-adapter";
  version = "2026-10-01";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-mcp-adapter";
    rev = "4bb5691096f29de490670cf18ddc4f81d20cd945";
    sha256 = "sha256-rhZuOISR5m1/vg9mjlzRjfgn68+QDTqvxsVRjpOdNYg=";
  };

  # Upstream ships its own package-lock.json, but the nested @earendil-works/*
  # dev dependencies are missing integrity fields, which makes prefetch-npm-deps
  # panic ("non-git dependencies should have associated integrity"). Inject the
  # published sha512 integrity hashes.
  postPatch = ''
    addIntegrity() {
      local package="$1"
      local integrity="$2"
      local resolved="https://registry.npmjs.org/@earendil-works/$package/-/$package-0.99.2.tgz"
      local missingIntegrity
      local withIntegrity
      missingIntegrity=$(printf '"resolved": "%s",\n      "dev": true,' "$resolved")
      withIntegrity=$(printf '"resolved": "%s",\n      "integrity": "%s",\n      "dev": true,' "$resolved" "$integrity")

      substituteInPlace package-lock.json \
        --replace-fail "$missingIntegrity" "$withIntegrity"
    }

    addIntegrity chord "sha512-2dJWiNsOJm/ioBl1fhpJmw0hIjFUhM0CAteEnVkiVG0Kg4LimR7Asq8PfjclEvrbCPsDntzy7rGKhTZObI9TZw=="
    addIntegrity pi-agent-core "sha512-VX0QMcg8HKBsv1bYP2NwmutBYa44OrwmtqR6Dq7QC3Ln8X/IlpHhUxB5L1JgnXNUUkTm8Wg/HZhzS797NBDMCQ=="
    addIntegrity pi-ai "sha512-9RFOEdY+ZTJ1AI+UuAFs4RM0tF2Tje/R/CEv9gWTJHt0iTu8XHZs64U/EIZxNSllFmec/4HfwsOxYj1qQek9bg=="
    addIntegrity pi-codemode "sha512-PVxNGu4l7LI92MvwUbaY3trjznU1Mlp2OMGwHwCWzLsjG7/lDa8xf6ei+Gws7VCt+Ri1tO+nFVl9KV2EeX7HWg=="
    addIntegrity pi-mcp "sha512-ISk6OIsiUzmULF+sUilLnENGKo9/gVDxZG2CTEq8f4dbp70AXOr/hMiwOjtcrlX6xBd4UMUsIz4EPTOlU6U+HA=="
    addIntegrity pi-telemetry "sha512-WThYU4XM6jjjzH4FzLdreN7QAPS9SDdokL0W0Ldheg1ssCIJkfpK7PgebFm7/PoQub7OiXx+SRF6B/oF7z7lXA=="
    addIntegrity pi-tui "sha512-IOcNnd390NCIwBEKeOiBK/bvaR7Z+vEsvB5TtKsFdsY/vAZE6qRHbQqt6jpTefTiKPfQlwG8eS1BU42DeG2v4w=="
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-kdrBeQOgQAl12F0/BPAE+SZbSHtNLdWCxyPFe5Ov8oI=";
}
