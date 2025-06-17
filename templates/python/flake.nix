{
  description = "Example Python Project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      perSystem = { pkgs, ... }:
        let
          python = pkgs.python3;
        in
        {
          devShells.default = pkgs.mkShell {
            venvDir = ".venv";

            postShellHook = ''
               venvVersionWarn() {
               	local venvVersion
              	  venvVersion="$("$venvDir/bin/python" -c 'import platform; print(platform.python_version())')"

               	[[ "$venvVersion" == "${python.version}" ]] && return

                 cat <<EOF
               Warning: Python version mismatch: [$venvVersion (venv)] != [${python.version}]
                        Delete '$venvDir' and reload to rebuild for version ${python.version}
               EOF
               }

               venvVersionWarn
            '';

            packages = with python.pkgs; [
              venvShellHook
              pip

              /* Add whatever else you'd like here. */
              # pkgs.black
              /* or */
              # python.pkgs.black
            ];
          };
        };
    };
}
