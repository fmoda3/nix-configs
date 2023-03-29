{
  description = "Frank Moda's nix configuration";
  inputs = {
    # Package sets
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-master.url = "github:nixos/nixpkgs/master";
    nixpkgs-stable-darwin.url = "github:nixos/nixpkgs/nixpkgs-22.11-darwin";
    nixos-stable.url = "github:nixos/nixpkgs/nixos-22.11";

    # Environment/system management
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        utils.follows = "flake-utils";
      };
    };

    # Other sources
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    neovim-flake = {
      url = "github:neovim/neovim?dir=contrib";
      inputs = {
        nixpkgs.url = "github:nixos/nixpkgs?rev=fad51abd42ca17a60fc1d4cb9382e2d79ae31836";
        flake-utils.follows = "flake-utils";
      };
    };
    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs = {
        nixpkgs.url = "github:nixos/nixpkgs?rev=fad51abd42ca17a60fc1d4cb9382e2d79ae31836";
        flake-compat.follows = "flake-compat";
        neovim-flake.follows = "neovim-flake";
      };
    };
    devshell = {
      url = "github:numtide/devshell";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        utils.follows = "flake-utils";
        flake-compat.follows = "flake-compat";
      };
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    comma = {
      url = "github:nix-community/comma";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        utils.follows = "flake-utils";
        flake-compat.follows = "flake-compat";
      };
    };
  };
  outputs = inputs@{ self, nixpkgs, darwin, home-manager, flake-utils, deploy-rs, devshell, nixos-generators, comma, ... }:
    let
      nixpkgsConfig = with inputs; {
        config = {
          allowUnfree = true;
        };
        overlays = [
          neovim-nightly-overlay.overlay
          comma.overlays.default
          # "pkgs" currently points to unstable
          # The following overlay allows you to specify "pkgs.stable" for stable versions
          # and "pkgs.master" for versions on master
          (
            final: prev:
              let
                inherit (prev.stdenv) system;
                nixpkgs-stable = if system == "x86_64-darwin" || system == "aarch64-darwin" then nixpkgs-stable-darwin else nixos-stable;
              in
              {
                master = nixpkgs-master.legacyPackages.${system};
                stable = nixpkgs-stable.legacyPackages.${system};
              }
          )
          # Add in custom defined packages in the pkgs directory
          (
            final: prev: { flake = self; } // import ./pkgs final prev
          )
        ];
      };
      darwinModules = { user, host }: with inputs; [
        # Main `nix-darwin` config
        (./. + "/hosts/${host}/configuration.nix")
        # `home-manager` module
        home-manager.darwinModules.home-manager
        {
          nixpkgs = nixpkgsConfig;
          # `home-manager` config
          users.users.${user}.home = "/Users/${user}";
          home-manager = {
            useGlobalPkgs = true;
            users.${user} = import (./. + "/hosts/${host}/home.nix");
          };
        }
      ];
      nixosModules = { user, host }: with inputs; [
        # Main `nixos` config
        (./. + "/hosts/${host}/configuration.nix")
        # `home-manager` module
        home-manager.nixosModules.home-manager
        {
          nixpkgs = nixpkgsConfig;
          # `home-manager` config
          users.users.${user} = {
            home = "/home/${user}";
            isNormalUser = true;
            group = "${user}";
            extraGroups = [ "wheel" ];
          };
          users.groups.${user} = { };
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.${user} = import (./. + "/hosts/${host}/home.nix");
          };
        }
      ];
    in
    {
      darwinConfigurations = {
        cicucci-imac = darwin.lib.darwinSystem {
          system = "x86_64-darwin";
          modules = darwinModules {
            user = "fmoda3";
            host = "cicucci-imac";
          };
          specialArgs = { inherit inputs nixpkgs; };
        };
        cicucci-laptop = darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = darwinModules {
            user = "fmoda3";
            host = "cicucci-laptop";
          };
          specialArgs = { inherit inputs nixpkgs; };
        };
        work-laptop = darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = darwinModules {
            user = "frank";
            host = "work-laptop";
          };
          specialArgs = { inherit inputs nixpkgs; };
        };
        macvm = darwin.lib.darwinSystem {
          system = "x86_64-darwin";
          modules = darwinModules {
            user = "fmoda3";
            host = "macvm";
          };
          specialArgs = { inherit inputs nixpkgs; };
        };
      };
      nixosConfigurations = {
        cicucci-dns = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = nixosModules {
            user = "fmoda3";
            host = "cicucci-dns";
          };
          specialArgs = { inherit inputs nixpkgs; };
        };
        cicucci-builder = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = nixosModules {
            user = "fmoda3";
            host = "cicucci-builder";
          };
          specialArgs = { inherit inputs nixpkgs; };
        };
      };
      images = {
        bootable-aarch64-sd = nixos-generators.nixosGenerate {
          system = "aarch64-linux";
          modules = nixosModules {
            user = "fmoda3";
            host = "bootable-sd";
          };
          specialArgs = { inherit inputs nixpkgs; };
          format = "sd-aarch64-installer";
        };
        bootable-aarch64-iso = nixos-generators.nixosGenerate {
          system = "aarch64-linux";
          modules = nixosModules {
            user = "fmoda3";
            host = "bootable-iso";
          };
          specialArgs = { inherit inputs nixpkgs; };
          format = "install-iso";
        };
        bootable-x86_64-iso = nixos-generators.nixosGenerate {
          system = "x86_64-linux";
          modules = nixosModules {
            user = "fmoda3";
            host = "bootable-iso";
          };
          specialArgs = { inherit inputs nixpkgs; };
          format = "install-iso";
        };
        cicucci-builder-vm = nixos-generators.nixosGenerate {
          system = "aarch64-linux";
          modules = nixosModules {
            user = "fmoda3";
            host = "cicucci-builder";
          };
          specialArgs = { inherit inputs nixpkgs; };
          format = "vmware";
        };
      };
      deploy = {
        nodes = {
          cicucci-dns = {
            hostname = "192.168.1.251";
            profiles.system = {
              user = "root";
              sshUser = "root";
              path = deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.cicucci-dns;
            };
          };
        };
      };
      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    } // flake-utils.lib.eachDefaultSystem (system: {
      devShells.default =
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ devshell.overlays.default ];
          };
        in
        pkgs.devshell.mkShell {
          packages = with pkgs; [
            nixpkgs-fmt
            deploy-rs.packages.${system}.deploy-rs
          ];
          commands = [
            {
              name = "format";
              help = "Format nix files with nixpkgs-fmt";
              command = "nixpkgs-fmt .";
            }
            {
              name = "create-aarch64-iso";
              help = "Creates an iso image for aarch64 with my configs";
              command = "GC_DONT_GC=1 nix build \".#images.bootable-aarch64-iso\"";
            }
            {
              name = "create-x86_64-iso";
              help = "Creates an iso image for x86_64 with my configs";
              command = "GC_DONT_GC=1 nix build \".#images.bootable-x86_64-iso\"";
            }
            {
              name = "create-aarch64-sd";
              help = "Creates an sd card image for aarch64 with my configs";
              command = "nix build \".#images.bootable-aarch64-sd\"";
            }
            {
              name = "create-builder-vm";
              help = "Creates a vmware image for cicucci-builder";
              command = "nix build \".#images.cicucci-builder-vm\"";
            }
          ];
        };
    });
}
