{ buildPiExtension }:

buildPiExtension {
  pname = "pi-toast";
  version = "2026-09-23";

  src = fetchGit {
    url = "git@github.toasttab.com:toasttab/pi-toast.git";
    rev = "d1dc45318450423a4797403bcedf1f6b649bb47e";
    ref = "main";
    narHash = "sha256-sOpGAX9fe6p034o0pcNXtCTSYh+JMb5C1O+3dJgcHbY=";
  };

  postPatch = ''
    addIntegrity() {
      local package="$1"
      local integrity="$2"
      local resolved="https://registry.npmjs.org/@earendil-works/$package/-/$package-0.87.1.tgz"
      local missingIntegrity
      local withIntegrity
      missingIntegrity=$(printf '"resolved": "%s",\n      "license": "MIT",\n      "peer": true,' "$resolved")
      withIntegrity=$(printf '"resolved": "%s",\n      "integrity": "%s",\n      "license": "MIT",\n      "peer": true,' "$resolved" "$integrity")

      substituteInPlace package-lock.json \
        --replace-fail "$missingIntegrity" "$withIntegrity"
    }

    addIntegrity chord "sha512-bg7IkJGFcEaMqqYgOGUiq5Ky9RghpRfrlZ8I/v/1b4bBZ02A7t3E+6uhPRbadwWb/kWsnVFbZsqOKRN4a3LLCg=="
    addIntegrity pi-agent-core "sha512-Zev3B0HK7YS5A4EZQ2XnEqiJuirx6QBiltJ+LpmjV5a/+2IU0cfKtIfnkNkORK707XOvKBY2WRtk7cAwHpbh2Q=="
    addIntegrity pi-ai "sha512-X/3PfQBnnoeVdO9Cv8zHghUMglzlgNZYGNzoPnbRoGnHl3Rw3TlA2UKSUB7BRHUOxMryHXYa8dnjWZlbRheDZA=="
    addIntegrity pi-telemetry "sha512-MC6TRQH5lgMXpcN+Vku2WMI2T8BsiUPzMQHGo81uqFZD3/9O79WWJAysEDGuzduP6R4tvtgwMLwmqIxynM10JQ=="
    addIntegrity pi-tui "sha512-YEH2vRyOeiO7hhN6j6AE6YwKSq2Kz2f3XR8bj1TbR+aGE/JsnY1hLPMI2pvaZfRM1n9Y00tejxFQ4zbzvF7nkQ=="
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-gvXnnZU8S8HIuVwsQJYN10HoyRY1h2y8Kf4CTnsefo8=";

  prunePaths = [
    ".github"
    "test"
  ];
}
