{
  description = "Frank Moda's nix configuration";
  inputs = {
    # Package sets
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-master.url = "github:nixos/nixpkgs/master";
    nixpkgs-stable-darwin.url = "github:nixos/nixpkgs/nixpkgs-26.05-darwin";
    nixos-stable.url = "github:nixos/nixpkgs/nixos-26.05";

    # Environment/system management
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Keep Hermes' own nixpkgs pin: its Python/toolchain versions are lock-derived.
    hermes-agent.url = "github:NousResearch/hermes-agent/ca069e12239a2c8d13887ac9f983557d00bdcfd2";

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
        systems.follows = "systems";
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
  outputs = inputs@{ self, nixpkgs, darwin, flake-parts, flake-root, treefmt-nix, devshell, nixos-generators, git-hooks, ... }:
    let
      # "pkgs" currently points to unstable
      # The following overlay allows you to specify "pkgs.stable" for stable versions
      # and "pkgs.master" for versions on master
      inherit (nixpkgs) lib;
      versionsOverlay = with inputs; (final: prev:
        let
          inherit (prev.stdenv.hostPlatform) system;
          nixpkgs-stable = if prev.stdenv.hostPlatform.isDarwin then nixpkgs-stable-darwin else nixos-stable;
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
      commonModules = { user, host, flakeRef }: with inputs; [
        # Main config
        (./. + "/hosts/${host}/configuration.nix")
        # `home-manager` module
        {
          nixpkgs = nixpkgsConfig;
          home-manager = {
            useGlobalPkgs = true;
            users.${user} = import (./. + "/hosts/${host}/home.nix");
            sharedModules = [
              nix-index-database.homeModules.nix-index
              agenix.homeManagerModules.default
              { config.my-home.flake = lib.mkDefault flakeRef; }
            ];
          };
        }
      ];
      darwinModules = { user, host, flakeRef }: with inputs;
        commonModules { inherit user host flakeRef; } ++ [
          agenix.darwinModules.default
          home-manager.darwinModules.home-manager
          {
            # `home-manager` config
            system.primaryUser = user;
            users.users.${user}.home = "/Users/${user}";
          }
        ];
      nixosModules = { user, host, flakeRef }: with inputs;
        commonModules { inherit user host flakeRef; } ++ [
          disko.nixosModules.disko
          agenix.nixosModules.default
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
        modules = darwinModules {
          inherit user host;
          flakeRef = ".#darwinConfigurations.${host}";
        };
        specialArgs = { inherit inputs nixpkgs; };
      };
      mkNixOSSystem = { user, host, system }: nixpkgs.lib.nixosSystem {
        inherit system;
        modules = nixosModules {
          inherit user host;
          flakeRef = ".#nixosConfigurations.${host}";
        };
        specialArgs = { inherit inputs nixpkgs; };
      };
      mkImage = { user, host, system, format }: nixos-generators.nixosGenerate {
        inherit system format;
        modules = nixosModules { inherit user host; flakeRef = ""; };
        specialArgs = { inherit inputs nixpkgs; };
      };
      mkInstaller = { user, host, system, format, targetSystem }: nixos-generators.nixosGenerate {
        inherit system format;
        modules = nixosModules { inherit user host; flakeRef = ""; } ++ installerModules { inherit targetSystem; };
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
          cicucci-server = mkDarwinSystem {
            system = "aarch64-darwin";
            user = "fmoda3";
            host = "cicucci-server";
          };
          work-laptop = mkDarwinSystem {
            system = "aarch64-darwin";
            user = "frank";
            host = "work-laptop";
          };
        };
        nixosConfigurations = {
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
        templates = import ./templates;
      };
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      perSystem = { config, inputs', pkgs, system, ... }: {
        legacyPackages = import nixpkgs (nixpkgsConfig // { inherit system; });
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
            src = lib.cleanSource ./.;
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
              command = "agenix -e \"$@\"";
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
              command = "agenix -d \"$@\"";
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
