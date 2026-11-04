{ buildPiExtension }:

let
  src = fetchGit {
    url = "git@github.toasttab.com:toasttab/pi-toast.git";
    rev = "e340da74c4a68bacdbbc2283be989c1e7769805f";
    ref = "main";
    narHash = "sha256-5Z07/5fC03leune9o243PsRgeggH7e6D4dnpy05iQ8E=";
  };
in
buildPiExtension {
  pname = "pi-toast";
  version = "2026-10-30";

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
