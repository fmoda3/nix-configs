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
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
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
      };
    };
  };
  outputs = inputs@{ self, nixpkgs, darwin, home-manager, flake-utils, deploy-rs, devshell, ... }:
    let
      nixpkgsConfig = with inputs; {
        config = {
          allowUnfree = true;
        };
        overlays = [
          # "pkgs" currently points to unstable
          # The following overlay allows you to specify "stable.pkgs" for stable versions
          # and "master.pkgs" for versions on master
          neovim-nightly-overlay.overlay
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
      nixosModules = { user, host, image ? null }: with inputs; [
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
      ] ++ (nixpkgs.lib.optional (image != null) image);
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
            image = "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix";
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
        bootable-aarch64-iso = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = nixosModules {
            user = "fmoda3";
            host = "bootable-iso";
            image = "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix";
          };
          specialArgs = { inherit inputs nixpkgs; };
        };
        bootable-x86_64-iso = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = nixosModules {
            user = "fmoda3";
            host = "bootable-iso";
            image = "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix";
          };
          specialArgs = { inherit inputs nixpkgs; };
        };
      };
      images = {
        cicucci-dns = self.nixosConfigurations.cicucci-dns.config.system.build.sdImage;
        bootable-aarch64-iso = self.nixosConfigurations.bootable-aarch64-iso.config.system.build.isoImage;
        bootable-x86_64-iso = self.nixosConfigurations.bootable-x86_64-iso.config.system.build.isoImage;
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
            overlays = [ devshell.overlay ];
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
              help = "Creates an iso image for aarch64 with my configs";
              command = "GC_DONT_GC=1 nix build \".#images.bootable-x86_64-iso\"";
            }
            {
              name = "create-cicucci-dns-sd";
              help = "Creates an sd card image for cicucci-dns";
              command = "nix build \".#images.cicucci-dns\"";
            }
          ];
        };
    });
}
