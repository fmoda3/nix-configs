{ writeShellApplication
, lib
, stdenv
, substituteAll
, coreutils
, gawk
, gnugrep
, nix
}:
writeShellApplication {
  name = "nix-cleanup";

  text = lib.readFile (substituteAll {
    src = ./nix-cleanup.sh;
    isNixOS = if stdenv.isLinux then "1" else "0";
  });

  runtimeInputs = [ coreutils gawk gnugrep nix ];
}
