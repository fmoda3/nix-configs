{ buildPiExtension }:

let
  src = fetchGit {
    url = "ssh://git@github.toasttab.com/toasttab/pi-toast.git";
    rev = "929c37c5853253185860007fda891b0ba4a5f01a";
    ref = "main";
    narHash = "sha256-4poCmFSKLEMDPYgBr1fXJfuMPT+KkuSsWnmrRQztDTc=";
  };
in
buildPiExtension {
  pname = "pi-toast";
  version = "2026-11-24";

  inherit src;

  npmDepsHash = "sha256-c7NnVIM/LF+27VUXZon1Y7aeCu90pxiAD6xMc7Uwvcs=";

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
