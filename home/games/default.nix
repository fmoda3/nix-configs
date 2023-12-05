{ config, pkgs, lib, ... }:
with lib;
let
  dwarf-fortress-package = if pkgs.stdenv.isDarwin then pkgs.pkgsx86_64Darwin.dwarf-fortress else pkgs.dwarf-fortress;
  dwarf-fortress-custom = dwarf-fortress-package.override {
    theme = "mayday";
    enableSoundSense = true;
  };
in
{
  config = mkIf config.my-home.includeGames {
    home = {
      packages = with pkgs; [
        dwarf-fortress-custom
        freesweep
        # gnuchess
        nethack
        ninvaders
        nudoku
        pacvim
        rogue
      ];
    };
  };
}
