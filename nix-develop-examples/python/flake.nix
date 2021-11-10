{
   description = "Example Python Project";

   inputs = {
     nixpkgs.url = "github:NixOS/nixpkgs/master";
     flake-utils.url = "github:numtide/flake-utils";
     mach-nix.url = "github:DavHau/mach-nix?ref=3.3.0";
   };

   outputs = { self, nixpkgs, flake-utils, mach-nix }:
     let
       # Customize starts
       python = "python39";
       devShell = pkgs:
         pkgs.mkShell {
           buildInputs = [
             (pkgs.${python}.withPackages
               (ps: with ps; [ pip black pyflakes isort ]))
           ];
         };
       # Customize ends
     in flake-utils.lib.eachDefaultSystem (system:
       let
         pkgs = nixpkgs.legacyPackages.${system};
         # https://github.com/DavHau/mach-nix/issues/153#issuecomment-717690154
         mach-nix-wrapper = import mach-nix { inherit pkgs python; };
         requirements = builtins.readFile ./requirements.txt;
         pythonShell = mach-nix-wrapper.mkPythonShell { inherit requirements; };
         mergeEnvs = envs:
           pkgs.mkShell (builtins.foldl' (a: v: {
             # runtime
             buildInputs = a.buildInputs ++ v.buildInputs;
             # build time
             nativeBuildInputs = a.nativeBuildInputs ++ v.nativeBuildInputs;
           }) (pkgs.mkShell { }) envs);
       in { devShell = mergeEnvs [ (devShell pkgs) pythonShell ]; });
 }
