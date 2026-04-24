{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-ghostty";
  version = "2026-02-14";

  src = fetchFromGitHub {
    owner = "HazAT";
    repo = "pi-ghostty";
    rev = "f414a831db7f097abc59fbc91f4e9296db2c092d";
    sha256 = "sha256-XxnqAqkQivzRw1YmNJAz1bJPdlugMU0BXRrmiO2x86c=";
  };

  prunePaths = [ ".github" ];

  postInstallCommands = ''
    # Add index.ts so Bun can resolve the "extensions" directory as a module
    echo 'export { default } from "./ghostty.ts";' > $out/extensions/index.ts
  '';
}
