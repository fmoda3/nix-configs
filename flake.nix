{
  description = "Frank Moda's nix configuration";
  inputs = {
    # Package sets
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-master.url = "github:nixos/nixpkgs/master";
    nixpkgs-stable-darwin.url = "github:nixos/nixpkgs/nixpkgs-23.05-darwin";
    nixos-stable.url = "github:nixos/nixpkgs/nixos-23.05";

    # Environment/system management
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Other sources
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-root.url = "github:srid/flake-root";
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    neovim-nightly-overlay = {
      # Don't follow nixpkgs for this, so that binary cache can be used.
      url = "github:nix-community/neovim-nightly-overlay?rev=88a6c749a7d126c49f3374f9f28ca452ea9419b8";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
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
  outputs = inputs@{ self, nixpkgs, darwin, flake-parts, flake-root, deploy-rs, treefmt-nix, devshell, nixos-generators, pre-commit-hooks, ... }:
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
          # Pins channels and flake registry to use the same nixpkgs as this flake.
          nix.registry = nixpkgs.lib.mapAttrs (_: value: { flake = value; }) inputs;
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
          # Pins channels and flake registry to use the same nixpkgs as this flake.
          nix.registry = nixpkgs.lib.mapAttrs (_: value: { flake = value; }) inputs;
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
      installerModules = { targetSystem }: [
        (./installer/system-installer.nix)
        { installer.targetSystem = targetSystem; }
      ];
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        devshell.flakeModule
        flake-root.flakeModule
        pre-commit-hooks.flakeModule
        treefmt-nix.flakeModule
      ];
      flake = {
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
          cicucci-arcade = nixpkgs.lib.nixosSystem {
            system = "aarch64-linux";
            modules = nixosModules {
              user = "fmoda3";
              host = "cicucci-arcade";
            };
            specialArgs = { inherit inputs nixpkgs; };
          };
        };
        images = {
          bootable-aarch64-sd = nixos-generators.nixosGenerate {
            system = "aarch64-linux";
            modules = nixosModules {
              user = "nixos";
              host = "bootable-sd";
            };
            specialArgs = { inherit inputs nixpkgs; };
            format = "sd-aarch64-installer";
          };
          bootable-aarch64-iso = nixos-generators.nixosGenerate {
            system = "aarch64-linux";
            modules = nixosModules {
              user = "nixos";
              host = "bootable-iso";
            };
            specialArgs = { inherit inputs nixpkgs; };
            format = "install-iso";
          };
          bootable-x86_64-iso = nixos-generators.nixosGenerate {
            system = "x86_64-linux";
            modules = nixosModules {
              user = "nixos";
              host = "bootable-iso";
            };
            specialArgs = { inherit inputs nixpkgs; };
            format = "install-iso";
          };
          cicucci-dns-sd = nixos-generators.nixosGenerate {
            system = "aarch64-linux";
            modules = nixosModules {
              user = "fmoda3";
              host = "cicucci-dns";
            };
            specialArgs = { inherit inputs nixpkgs; };
            format = "sd-aarch64";
          };
          cicucci-builder-iso = nixos-generators.nixosGenerate {
            system = "aarch64-linux";
            modules = nixpkgs.lib.flatten [
              (nixosModules {
                user = "nixos";
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
          cicucci-arcade-iso = nixos-generators.nixosGenerate {
            system = "aarch64-linux";
            modules = nixpkgs.lib.flatten [
              (nixosModules {
                user = "nixos";
                host = "bootable-iso";
              })
              (installerModules {
                targetSystem = self.nixosConfigurations.cicucci-arcade;
              })
            ];
            specialArgs = { inherit inputs nixpkgs; };
            format = "install-iso";
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
        templates = import ./templates;
      };
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      perSystem = { config, self', inputs', pkgs, system, ... }: {
        treefmt.config = {
          inherit (config.flake-root) projectRootFile;
          programs.nixpkgs-fmt.enable = true;
          programs.stylua.enable = true;
        };
        pre-commit = {
          check.enable = true;
          settings = {
            src = ./.;
            hooks = {
              nixpkgs-fmt.enable = true;
              statix.enable = true;
              stylua.enable = true;
            };
          };
        };
        devshells.default = {
          devshell.startup.pre-commit.text = config.pre-commit.installationScript;
          packages = with pkgs; [
            statix
            inputs'.deploy-rs.packages.default
          ];
          commands = [
            {
              name = "format";
              help = "Format nix files with nixpkgs-fmt";
              command = "nix fmt";
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
              name = "create-dns-sd";
              help = "Creates a vmware image for cicucci-builder";
              command = "nix build \".#images.cicucci-dns-sd\"";
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
            {
              name = "create-arcade-iso";
              help = "Creates a vmware image for cicucci-arcade";
              command = "nix build \".#images.cicucci-arcade-iso\"";
            }
          ];
        };
      };
    };
}
