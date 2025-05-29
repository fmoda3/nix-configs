{ config, pkgs, lib, ... }:
with lib;
{
  # Hide the dock and menu bar, for Yabai
  system.defaults = {
    dock = {
      autohide = true;
    };
    NSGlobalDomain = {
      _HIHideMenuBar = true;
    };
  };

  services = {
    yabai = {
      enable = false;
      package = pkgs.yabai;
      enableScriptingAddition = true;
      config = {
        mouse_follows_focus = "off";
        focus_follows_mouse = "off";
        window_placement = "second_child";
        window_topmost = "on";
        window_opacity = "off";
        window_opacity_duration = "0.0";
        window_shadow = "float";
        window_border = "on";
        window_border_width = "4";
        active_window_opacity = "1.0";
        normal_window_opacity = "0.90";
        split_ratio = "0.50";
        auto_balance = "on";
        mouse_modifier = "fn";
        mouse_action1 = "move";
        mouse_action2 = "resize";
        mouse_drop_action = "swap";

        layout = "bsp";
        top_padding = "20";
        bottom_padding = "20";
        left_padding = "20";
        right_padding = "20";
        window_gap = "10";
        external_bar = "all:26:0"; # let simple-bar handle bar
        # Catppuccin theme
        active_window_border_color = "0xFF8CAAEE";
        normal_window_border_color = "0xFF626880";
        insert_window_border_color = "0xFFE78284";
      };
      extraConfig = ''
        yabai -m rule --add app="choose" manage=off

        # Space labels
        yabai -m space 1 --label "Term"
        yabai -m space 2 --label "Dev"
        yabai -m space 3 --label "Web"
        yabai -m space 4 --label "Email"
        yabai -m space 5 --label "Social"
        yabai -m space 6 --label "Media"
        yabai -m space 7 --label "Games"
        yabai -m space 8 --label "Tools"
        yabai -m space 9 --label "Float"
        yabai -m space 10 --label "Misc"

        # Make float space
        yabai -m space 9 --layout float

        # Unmanaged
        yabai -m rule --add app="^System Preferences$" sticky=on layer=above manage=off    
      '';
    };

    spacebar = {
      enable = true;
      package = pkgs.spacebar;
      config = {
        text_font = ''"TerminessTTF Nerd Font:Medium:12.0"'';
        icon_font = ''"TerminessTTF Nerd Font:Medium:12.0"'';
        position = "top";
        height = 26;
        spacing_left = 25;
        spacing_right = 15;
        space_icon_strip = "         ";
        power_icon_strip = " ";
        space_icon = "";
        clock_icon = "";
        dnd_icon = "";
        clock_format = ''"%d/%m/%y %R"'';
        # Catppuccin theme
        background_color = "0xff303446";
        foreground_color = "0xff8caaee";
        space_icon_color = "0xffe78284";
        power_icon_color = "0xffef9f76";
        battery_icon_color = "0xffe5c890";
        dnd_icon_color = "0xffa6d189";
        clock_icon_color = "0xfff4b8e4";
      };
    };

    skhd = {
      enable = true;
      package = pkgs.skhd;
      skhdConfig = ''
        # focus window
        alt - j : yabai -m window --focus west
        alt - k : yabai -m window --focus south
        alt - i : yabai -m window --focus north
        alt - l : yabai -m window --focus east

        # swap window
        shift + alt - j : yabai -m window --swap west
        shift + alt - k : yabai -m window --swap south
        shift + alt - i : yabai -m window --swap north
        shift + alt - l : yabai -m window --swap east

        # move window
        shift + cmd - j : yabai -m window --warp west
        shift + cmd - k : yabai -m window --warp south
        shift + cmd - i : yabai -m window --warp north
        shift + cmd - l : yabai -m window --warp east

        # balance size of windows
        shift + alt - 0 : yabai -m space --balance

        # make floating window fill screen
        shift + alt - up     : yabai -m window --grid 1:1:0:0:1:1

        # make floating window fill left-half of screen
        shift + alt - left   : yabai -m window --grid 1:2:0:0:1:1

        # make floating window fill right-half of screen
        shift + alt - right  : yabai -m window --grid 1:2:1:0:1:1

        # create desktop
        cmd + alt - n : yabai -m space --create

        # destroy desktop
        cmd + alt - w : yabai -m space --destroy

        # fast focus desktop
        cmd + alt - x : yabai -m space --focus recent
        cmd + alt - z : yabai -m space --focus prev
        cmd + alt - c : yabai -m space --focus next
        cmd - 1 : yabai -m space --focus 1
        cmd - 2 : yabai -m space --focus 2
        cmd - 3 : yabai -m space --focus 3
        cmd - 4 : yabai -m space --focus 4
        cmd - 5 : yabai -m space --focus 5
        cmd - 6 : yabai -m space --focus 6
        cmd - 7 : yabai -m space --focus 7
        cmd - 8 : yabai -m space --focus 8
        cmd - 9 : yabai -m space --focus 9
        cmd - 0 : yabai -m space --focus 10

        # send window to desktop and follow focus
        shift + cmd - x : yabai -m window --space recent; yabai -m space --focus recent
        shift + cmd - z : yabai -m window --space prev; yabai -m space --focus prev
        shift + cmd - c : yabai -m window --space next; yabai -m space --focus next
        shift + cmd - 1 : yabai -m window --space  1; yabai -m space --focus 1
        shift + cmd - 2 : yabai -m window --space  2; yabai -m space --focus 2
        shift + cmd - 3 : yabai -m window --space  3; yabai -m space --focus 3
        shift + cmd - 4 : yabai -m window --space  4; yabai -m space --focus 4
        shift + cmd - 5 : yabai -m window --space  5; yabai -m space --focus 5
        shift + cmd - 6 : yabai -m window --space  6; yabai -m space --focus 6
        shift + cmd - 7 : yabai -m window --space  7; yabai -m space --focus 7
        shift + cmd - 8 : yabai -m window --space  8; yabai -m space --focus 8
        shift + cmd - 9 : yabai -m window --space  9; yabai -m space --focus 9
        shift + cmd - 0 : yabai -m window --space 10; yabai -m space --focus 10

        # focus monitor
        ctrl + alt - x  : yabai -m display --focus recent
        ctrl + alt - z  : yabai -m display --focus prev
        ctrl + alt - c  : yabai -m display --focus next
        ctrl + alt - 1  : yabai -m display --focus 1
        ctrl + alt - 2  : yabai -m display --focus 2
        ctrl + alt - 3  : yabai -m display --focus 3

        # move window
        shift + ctrl - a : yabai -m window --move rel:-20:0
        shift + ctrl - s : yabai -m window --move rel:0:20
        shift + ctrl - w : yabai -m window --move rel:0:-20
        shift + ctrl - d : yabai -m window --move rel:20:0

        # increase window size
        shift + alt - a : yabai -m window --resize left:-20:0
        shift + alt - s : yabai -m window --resize bottom:0:20
        shift + alt - w : yabai -m window --resize top:0:-20
        shift + alt - d : yabai -m window --resize right:20:0

        # decrease window size
        #shift + cmd - a : yabai -m window --resize left:20:0
        #shift + cmd - s : yabai -m window --resize bottom:0:-20
        #shift + cmd - w : yabai -m window --resize top:0:20
        #shift + cmd - d : yabai -m window --resize right:-20:0

        # set insertion point in focused container
        ctrl + alt - h : yabai -m window --insert west
        ctrl + alt - j : yabai -m window --insert south
        ctrl + alt - k : yabai -m window --insert north
        ctrl + alt - l : yabai -m window --insert east

        # rotate tree
        alt - r : yabai -m space --rotate 90

        # mirror tree y-axis
        alt - y : yabai -m space --mirror y-axis

        # mirror tree x-axis
        alt - x : yabai -m space --mirror x-axis

        # toggle desktop offset
        alt - a : yabai -m space --toggle padding; yabai -m space --toggle gap

        # toggle window parent zoom
        alt - d : yabai -m window --toggle zoom-parent

        # toggle window fullscreen zoom
        alt - f : yabai -m window --toggle zoom-fullscreen

        # toggle window native fullscreen
        shift + alt - f : yabai -m window --toggle native-fullscreen

        # toggle window border
        shift + alt - b : yabai -m window --toggle border

        # toggle window split type
        alt - e : yabai -m window --toggle split

        # float / unfloat window and center on screen
        alt - t : yabai -m window --toggle float;\
                  yabai -m window --grid 4:4:1:1:2:2

        # toggle sticky (show on all spaces)
        alt - s : yabai -m window --toggle sticky

        # toggle topmost (keep above other windows)
        alt - o : yabai -m window --toggle topmost

        # toggle sticky, topmost and resize to picture-in-picture size
        alt - p : yabai -m window --toggle sticky;\
                  yabai -m window --toggle topmost;\
                  yabai -m window --grid 5:5:4:0:1:1

        # change layout of desktop
        ctrl + alt - a : yabai -m space --layout bsp
        ctrl + alt - d : yabai -m space --layout float

        # Custom stuff
        :: passthrough
        ctrl + cmd - p ; passthrough
        passthrough < ctrl + cmd - p ; default

        # open terminal
        cmd - return : open -a kitty
        ctrl + alt - t : open -a kitty

        # lock screen
        cmd - l : /System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession -suspend
      '';
    };
  };
}
