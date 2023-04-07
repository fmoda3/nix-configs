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
    neovim-nightly-overlay = {
      # Don't follow nixpkgs for this, so that binary cache can be used.
      url = "github:nix-community/neovim-nightly-overlay";
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
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:Mic92/nix-index-database";
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
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixpkgs-stable.follows = "nixos-stable";
        flake-utils.follows = "flake-utils";
        flake-compat.follows = "flake-compat";
      };
    };
  };
  outputs = inputs@{ self, nixpkgs, darwin, flake-utils, deploy-rs, devshell, nixos-generators, pre-commit-hooks, ... }:
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
            sharedModules = [
              nix-index-database.hmModules.nix-index
            ];
          };
        }
      ];
      nixosModules = { user, host }: with inputs; [
        # Main `nixos` config
        (./. + "/hosts/${host}/configuration.nix")
        disko.nixosModules.disko
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
            sharedModules = [
              nix-index-database.hmModules.nix-index
            ];
          };
        }
      ];
      installerModules = { targetSystem }: with inputs; [
        (./installer/system-installer.nix)
        { installer.targetSystem = targetSystem; }
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
        cicucci-builder-iso = nixos-generators.nixosGenerate {
          system = "aarch64-linux";
          modules = nixpkgs.lib.flatten [
            (nixosModules {
              user = "fmoda3";
              host = "bootable-iso";
            })
            (installerModules {
              targetSystem = self.nixosConfigurations.cicucci-builder;
            })
          ];
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
      checks = {
        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            nixpkgs-fmt.enable = true;
            statix.enable = true;
          };
        };
      };
      devShells.default =
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ devshell.overlays.default ];
          };
        in
        pkgs.devshell.mkShell {
          devshell.startup.pre-commit.text = self.checks.${system}.pre-commit-check.shellHook;
          packages = with pkgs; [
            nixpkgs-fmt
            statix
            deploy-rs.packages.${system}.deploy-rs
          ];
          commands = [
            {
              name = "format";
              help = "Format nix files with nixpkgs-fmt";
              command = "nixpkgs-fmt $PRJ_ROOT";
            }
            {
              name = "lint";
              help = "Run lint checker with statix";
              command = "statix fix $PRJ_ROOT";
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
              name = "create-builder-iso";
              help = "Creates a vmware image for cicucci-builder";
              command = "nix build \".#images.cicucci-builder-iso\"";
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
