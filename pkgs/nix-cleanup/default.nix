{ writeShellApplication
, lib
, stdenv
, coreutils
, gawk
, gnugrep
, nix
}:
writeShellApplication {
  name = "nix-cleanup";

  text = lib.replaceStrings
    [ "@isNixOS@" ]
    [ (if stdenv.isLinux then "1" else "0") ]
    (builtins.readFile ./nix-cleanup.sh);

  runtimeInputs = [ coreutils gawk gnugrep nix ];
}
