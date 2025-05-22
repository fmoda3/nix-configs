{
  description = "Frank Moda's nix configuration";
  inputs = {
    # Package sets
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-master.url = "github:nixos/nixpkgs/master";
    nixpkgs-stable-darwin.url = "github:nixos/nixpkgs/nixpkgs-24.11-darwin";
    nixos-stable.url = "github:nixos/nixpkgs/nixos-24.11";

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
    systems.url = "github:nix-systems/default";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-root.url = "github:srid/flake-root";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        darwin.follows = "darwin";
        home-manager.follows = "home-manager";
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
    naersk = {
      url = "github:nix-community/naersk/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    comma = {
      url = "github:nix-community/comma";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        naersk.follows = "naersk";
        utils.follows = "flake-utils";
        flake-compat.follows = "flake-compat";
      };
    };
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "flake-compat";
      };
    };
  };
  outputs = inputs@{ self, nixpkgs, darwin, flake-parts, flake-root, deploy-rs, treefmt-nix, devshell, nixos-generators, git-hooks, ... }:
    let
      # "pkgs" currently points to unstable
      # The following overlay allows you to specify "pkgs.stable" for stable versions
      # and "pkgs.master" for versions on master
      versionsOverlay = with inputs; (final: prev:
        let
          inherit (prev.stdenv) system;
          nixpkgs-stable = if prev.stdenv.isDarwin then nixpkgs-stable-darwin else nixos-stable;
        in
        {
          master = nixpkgs-master.legacyPackages.${system};
          stable = nixpkgs-stable.legacyPackages.${system};
        }
      );
      # Add in custom defined packages in the pkgs directory
      customPackagesOverlay = final: prev: { flake = self; } // import ./pkgs final prev;
      nixpkgsConfig = with inputs; {
        config = {
          allowUnfree = true;
        };
        overlays = [
          comma.overlays.default
          versionsOverlay
          customPackagesOverlay
        ];
      };
      commonModules = { user, host }: with inputs; [
        # Main config
        (./. + "/hosts/${host}/configuration.nix")
        agenix.darwinModules.default
        # `home-manager` module
        {
          nixpkgs = nixpkgsConfig;
          home-manager = {
            useGlobalPkgs = true;
            users.${user} = import (./. + "/hosts/${host}/home.nix");
            sharedModules = [
              nix-index-database.hmModules.nix-index
              agenix.homeManagerModules.default
              {
                age.secrets.anthropic_ai_key.file = secrets/anthropic_ai_key.age;
                age.secrets.openrouter_key.file = secrets/openrouter_key.age;
              }
            ];
          };
        }
      ];
      darwinModules = { user, host }: with inputs;
        commonModules { inherit user host; } ++ [
          home-manager.darwinModules.home-manager
          {
            # `home-manager` config
            system.primaryUser = user;
            users.users.${user}.home = "/Users/${user}";
          }
        ];
      nixosModules = { user, host }: with inputs;
        commonModules { inherit user host; } ++ [
          disko.nixosModules.disko
          home-manager.nixosModules.home-manager
          {
            # `home-manager` config
            users.users.${user} = {
              home = "/home/${user}";
              isNormalUser = true;
              group = "${user}";
              extraGroups = [ "wheel" ];
            };
            users.groups.${user} = { };
            home-manager.useUserPackages = true;
          }
        ];
      installerModules = { targetSystem }: [
        ./installer/system-installer.nix
        { installer.targetSystem = targetSystem; }
      ];
      mkDarwinSystem = { user, host, system }: darwin.lib.darwinSystem {
        inherit system;
        modules = darwinModules { inherit user host; };
        specialArgs = { inherit inputs nixpkgs; };
      };
      mkNixOSSystem = { user, host, system }: nixpkgs.lib.nixosSystem {
        inherit system;
        modules = nixosModules { inherit user host; };
        specialArgs = { inherit inputs nixpkgs; };
      };
      mkImage = { user, host, system, format }: nixos-generators.nixosGenerate {
        inherit system format;
        modules = nixosModules { inherit user host; };
        specialArgs = { inherit inputs nixpkgs; };
      };
      mkInstaller = { user, host, system, format, targetSystem }: nixos-generators.nixosGenerate {
        inherit system format;
        modules = nixosModules { inherit user host; } ++ installerModules { inherit targetSystem; };
        specialArgs = { inherit inputs nixpkgs; };
      };
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        devshell.flakeModule
        flake-root.flakeModule
        git-hooks.flakeModule
        treefmt-nix.flakeModule
      ];
      flake = {
        darwinConfigurations = {
          cicucci-desktop = mkDarwinSystem {
            system = "aarch64-darwin";
            user = "fmoda3";
            host = "cicucci-desktop";
          };
          cicucci-laptop = mkDarwinSystem {
            system = "aarch64-darwin";
            user = "fmoda3";
            host = "cicucci-laptop";
          };
          work-laptop = mkDarwinSystem {
            system = "aarch64-darwin";
            user = "frank";
            host = "work-laptop";
          };
        };
        nixosConfigurations = {
          cicucci-dns = mkNixOSSystem {
            system = "aarch64-linux";
            user = "fmoda3";
            host = "cicucci-dns";
          };
          cicucci-homelab = mkNixOSSystem {
            system = "x86_64-linux";
            user = "fmoda3";
            host = "cicucci-homelab";
          };
          cicucci-builder = mkNixOSSystem {
            system = "aarch64-linux";
            user = "fmoda3";
            host = "cicucci-builder";
          };
        };
        images = {
          bootable-aarch64-sd = mkImage {
            system = "aarch64-linux";
            user = "nixos";
            host = "bootable-sd";
            format = "sd-aarch64-installer";
          };
          bootable-aarch64-iso = mkImage {
            system = "aarch64-linux";
            user = "nixos";
            host = "bootable-iso";
            format = "install-iso";
          };
          bootable-x86_64-iso = mkImage {
            system = "x86_64-linux";
            user = "nixos";
            host = "bootable-iso";
            format = "install-iso";
          };
          cicucci-dns-sd = mkImage {
            system = "aarch64-linux";
            user = "fmoda3";
            host = "cicucci-dns";
            format = "sd-aarch64";
          };
          cicucci-builder-vm = mkImage {
            system = "aarch64-linux";
            user = "fmoda3";
            host = "cicucci-builder";
            format = "vmware";
          };
          cicucci-builder-iso = mkInstaller {
            system = "aarch64-linux";
            user = "nixos";
            host = "bootable-iso";
            format = "install-iso";
            targetSystem = self.nixosConfigurations.cicucci-builder;
          };
          cicucci-homelab-iso = mkInstaller {
            system = "x86_64-linux";
            user = "nixos";
            host = "bootable-iso";
            format = "install-iso";
            targetSystem = self.nixosConfigurations.cicucci-homelab;
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
      perSystem = { config, inputs', pkgs, ... }: {
        treefmt.config = {
          inherit (config.flake-root) projectRootFile;
          programs = {
            nixpkgs-fmt.enable = true;
            statix.enable = true;
            stylua.enable = true;
          };
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
            nixd
            statix
            inputs'.deploy-rs.packages.default
            inputs'.agenix.packages.default
          ];
          commands = [
            {
              name = "format";
              category = "style";
              help = "Format nix files with nixpkgs-fmt";
              command = "nix fmt";
            }
            {
              name = "lint";
              category = "style";
              help = "Run lint checker with statix";
              command = "statix fix $PRJ_ROOT";
            }
            {
              name = "age-edit";
              category = "secrets";
              help = "Edit an age file";
              command = "agenix -e $@";
            }
            {
              name = "age-rekey";
              category = "secrets";
              help = "Rekey all age files";
              command = "agenix -r";
            }
            {
              name = "age-decrypt";
              category = "secrets";
              help = "Decrypt an age file";
              command = "agenix -d $@";
            }
            {
              name = "create-aarch64-iso";
              category = "image builds";
              help = "Creates an iso image for aarch64 with my configs";
              command = "GC_DONT_GC=1 nix build \".#images.bootable-aarch64-iso\"";
            }
            {
              name = "create-x86_64-iso";
              category = "image builds";
              help = "Creates an iso image for x86_64 with my configs";
              command = "GC_DONT_GC=1 nix build \".#images.bootable-x86_64-iso\"";
            }
            {
              name = "create-aarch64-sd";
              category = "image builds";
              help = "Creates an sd card image for aarch64 with my configs";
              command = "nix build \".#images.bootable-aarch64-sd\"";
            }
            {
              name = "create-dns-sd";
              category = "image builds";
              help = "Creates an sd image for cicucci-dns";
              command = "nix build \".#images.cicucci-dns-sd\"";
            }
            {
              name = "create-homelab-iso";
              category = "image builds";
              help = "Creates an iso image for cicucci-homelab";
              command = "nix build \".#images.cicucci-homelab-iso\"";
            }
            {
              name = "create-builder-iso";
              category = "image builds";
              help = "Creates an iso image for cicucci-builder";
              command = "nix build \".#images.cicucci-builder-iso\"";
            }
            {
              name = "create-builder-vm";
              category = "image builds";
              help = "Creates a vmware image for cicucci-builder";
              command = "nix build \".#images.cicucci-builder-vm\"";
            }
          ];
        };
      };
    };
}
