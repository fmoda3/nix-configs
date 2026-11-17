{ buildPiExtension }:

let
  src = fetchGit {
    url = "git@github.toasttab.com:toasttab/pi-toast.git";
    rev = "d357e5542b0678054491a7c14f87d4296dee057b";
    ref = "main";
    narHash = "sha256-jI4VfdkFFppaxHUKGTE/xXoDNARILfR2LIJ3okYzqzw=";
  };
in
buildPiExtension {
  pname = "pi-toast";
  version = "2026-11-17";

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
