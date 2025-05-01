{ writeShellApplication
, lib
, stdenv
, replaceVars
, coreutils
, gawk
, gnugrep
, nix
}:
writeShellApplication {
  name = "nix-cleanup";

  text = lib.readFile (replaceVars ./nix-cleanup.sh {
    isNixOS = if stdenv.isLinux then "1" else "0";
  });

  runtimeInputs = [ coreutils gawk gnugrep nix ];
}
