{
  description = "Frank Moda's nix configuration";
  inputs = {
    # Package sets
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-master.url = "github:nixos/nixpkgs/master";
    nixpkgs-stable-darwin.url = "github:nixos/nixpkgs/nixpkgs-22.05-darwin";
    nixos-stable.url = "github:nixos/nixpkgs/nixos-22.05";
  
    # Environment/system management
    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  
    # Other sources
    flake-utils.url = "github:numtide/flake-utils";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
  };
  outputs = inputs@{ self, nixpkgs, darwin, home-manager, flake-utils, ... }:
    let
      nixpkgsConfig = with inputs; {
        config = {
          allowUnfree = true;
          allowUnsupportedSystem = true;
          allowBroken = true; # Delete when pyopenssl fixed for M1 machines
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
            in {
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
            users.${user} = with self.homeManagerModules; {
              imports = [ (./. + "/hosts/${host}/home.nix") ];
            };
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
            group = "fmoda3";
            extraGroups = [ "wheel" ];
          };
          users.groups.${user} = {};
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.${user} = with self.homeManagerModules; {
              imports = [ (./. + "/hosts/${host}/home.nix") ];
            };
          };
        }
      ];
    in {
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
        ## Example nixos instance
        # nano = nixpkgs.lib.nixosSystem {
        #   system = "x86_64-linux";
        #   modules = nixosModules {
        #     user = "fmoda3";
        #     host = "nano";
        #   };
        #   specialArgs = { inherit inputs nixpkgs; };
        # };
      };
    };
}
