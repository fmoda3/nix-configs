{ buildPiExtension }:

let
  src = fetchGit {
    url = "git@github.toasttab.com:toasttab/pi-toast.git";
    rev = "b0677e7e698ece7b9b88353395a0d0220dc381a1";
    ref = "main";
    narHash = "sha256-gkJ2JVnZBSDwEXvBWpmIBSlP6lcdwG9ayzRDWo+5Bgg=";
  };
in
buildPiExtension {
  pname = "pi-toast";
  version = "2026-11-18";

  inherit src;

  npmDepsHash = "sha256-y523EPcHA4lBEt0SGZ9uckwn/YpgIUwbA58gXfEpmwE=";

  prunePaths = [
    ".github"
    "test"
  ];

  # fetchGit strips .git, so pi-toast's telemetry can't read its own commit
  # (pi_toast.commit). A detached HEAD holding the pinned rev is all it reads.
  postInstallCommands = ''
    mkdir -p "$out/.git"
    echo "${src.rev}" > "$out/.git/HEAD"
  '';
}
