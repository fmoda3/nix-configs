{config, pkgs, ...}:
{
  services.yabai.enable = true;
  services.yabai.package = pkgs.yabai;
  services.yabai.enableScriptingAddition = true;
  services.yabai.extraConfig = ''
    # let simple-bar handle bar
    yabai -m config external_bar all:10:0 

    yabai -m config mouse_follows_focus          off
    yabai -m config focus_follows_mouse          off
    yabai -m config window_placement             second_child
    yabai -m config window_topmost               on
    yabai -m config window_opacity               off
    yabai -m config window_opacity_duration      0.0
    yabai -m config window_shadow                float
    yabai -m config window_border                on
    yabai -m config window_border_width          4
    yabai -m config active_window_border_color   0xFF8FBCBB
    yabai -m config normal_window_border_color   0xFF5E81AC
    yabai -m config insert_window_border_color   0xFFBF616A
    yabai -m config active_window_opacity        1.0
    yabai -m config normal_window_opacity        0.90
    yabai -m config split_ratio                  0.50
    yabai -m config auto_balance                 on
    yabai -m config mouse_modifier               fn
    yabai -m config mouse_action1                move
    yabai -m config mouse_action2                resize
    yabai -m config mouse_drop_action		 swap
    
    yabai -m config layout                       bsp
    yabai -m config top_padding                  20
    yabai -m config bottom_padding               20
    yabai -m config left_padding                 20
    yabai -m config right_padding                20
    yabai -m config window_gap                   10
    yabai -m rule --add app="choose" manage=off

    # Space labels
    yabai -m space 1 --label "Term 1"
    yabai -m space 2 --label "Dev 2"
    yabai -m space 3 --label "Web 3"
    yabai -m space 4 --label "Email 4"
    yabai -m space 5 --label "Social 5"
    yabai -m space 6 --label "Media 6"
    yabai -m space 7 --label "Games 7"
    yabai -m space 8 --label "Tools 8"
    yabai -m space 9 --label "Float 9"
    yabai -m space 10 --label "Misc 10"

    # Unmanaged
    yabai -m rule --add app="^System Preferences$" sticky=on layer=above manage=off    
  '';

  services.spacebar.enable = true;
  services.spacebar.package = pkgs.spacebar;
  services.spacebar.config = {
    position 	       = "top";
    height	       = 26;
    spacing_left       = 25;
    spacing_right      = 15;
    text_font	       = ''"TerminessTTF Nerd Font:Medium:12.0"'';
    icon_font	       = ''"TerminessTTF Nerd Font:Medium:12.0"'';
    background_color   = "0xff2e3440";
    foreground_color   = "0xff5e81ac";
    space_icon_color   = "0xffbf616a";
    power_icon_color   = "0xffd08770";
    battery_icon_color = "0xffebcb8b";
    dnd_icon_color     = "0xffa3be8c";
    clock_icon_color   = "0xffb48ead";
    space_icon_strip   = "         ";
    power_icon_strip   = " ";
    space_icon         = "";
    clock_icon         = "";
    dnd_icon           = "";
    clock_format       = ''"%d/%m/%y %R"'';
  };

  services.skhd.enable = true;
  services.skhd.package =  pkgs.skhd;
  services.skhd.skhdConfig = ''
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
}
