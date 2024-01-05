{
  description = "Example Elixir Project";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ self, nixpkgs, flake-parts }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      perSystem = { config, self', inputs', pkgs, system, ... }:
        let
          basePackages = with pkgs; [
            beam.packages.erlang.elixir
            beam.interpreters.erlang
          ];

          inputs = with pkgs;
            basePackages ++ lib.optionals stdenv.isLinux [ gigalixir inotify-tools libnotify ]
            ++ lib.optionals stdenv.isDarwin [ terminal-notifier ] ++
            (with darwin.apple_sdk.frameworks; [ CoreFoundation CoreServices ]);

          hooks = ''
            # this allows mix to work on the local directory
            mkdir -p .nix-mix .nix-hex
            export MIX_HOME=$PWD/.nix-mix
            export HEX_HOME=$PWD/.nix-hex
            export PATH=$MIX_HOME/bin:$MIX_HOME/escripts:$HEX_HOME/bin:$PATH
            # TODO: not sure how to make hex available without installing it afterwards.
            mix local.hex --if-missing
            export LANG=en_US.UTF-8
            export ERL_AFLAGS="-kernel shell_history enabled"
          '';
        in
        {
          devShells.default = pkgs.mkShell {
            packages = inputs;
            shellHook = hooks;
          };
        };
    };
}
