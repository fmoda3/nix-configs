{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    shortcut = "a";
    baseIndex = 1;
    terminal = "screen-256color";
    keyMode = "vi";
    historyLimit = 10000;
    escapeTime = 1;
    customPaneNavigationAndResize = true;
    resizeAmount = 5;

    plugins = with pkgs.tmuxPlugins; [
      sensible
    ];

    extraConfig = ''
      # Set default terminal
      set -g default-terminal "tmux-256color"

      # Set theme
      set -g @catppuccin_flavor 'frappe' # latte, frappe, macchiato or mocha
      set -g @catppuccin_window_status_style "rounded"
      set -g @catppuccin_window_text " #{b:pane_current_path}"
      set -g @catppuccin_window_current_text " #{b:pane_current_path}"
      run-shell ${pkgs.tmuxPlugins.catppuccin}/share/tmux-plugins/catppuccin/catppuccin.tmux
      
      # Need to override sensible
      set -g default-command '$SHELL'

      # splitting panes
      # START:panesplit
      bind | split-window -h
      bind - split-window -v
      # END:panesplit

      # Quick pane selection
      # START:panetoggle
      bind -r C-h select-window -t :-
      bind -r C-l select-window -t :+
      # END:panetoggle

      # mouse support - set to on if you want to use the mouse
      # START:mouse
      setw -g mouse off 
      # END:mouse

      # enable activity alerts
      #START:activity
      setw -g monitor-activity on
      set -g visual-activity on
      setw -g window-status-activity-style none
      #END:activity

      # Ring the bell if any background window rang a bell
      set -g bell-action any

      # Keep your finger on ctrl, or don't
      bind-key ^D detach-client

      # easily toggle synchronization (mnemonic: e is for echo)
      # sends input to all panes in a given window.
      bind e setw synchronize-panes

      # color scheme (styled as vim-powerline)
      set -g status-right-length 100
      set -g status-left-length 100
      set -g status-left ""
      set -g status-right "#{E:@catppuccin_status_application}"
      set -agF status-right "#{E:@catppuccin_status_cpu}"
      set -ag status-right "#{E:@catppuccin_status_session}"
      set -ag status-right "#{E:@catppuccin_status_uptime}"
      set -agF status-right "#{E:@catppuccin_status_battery}"

      # Screen like binding for last window
      bind C-a last-window

      # Log output to a text file on demand
      # START:pipe-pane
      bind P pipe-pane -o "cat >>~/#W.log" \; display "Toggled logging to ~/#W.log"
      # END:pipe-pane

      # Neovim color compatibility
      set-option -sa terminal-overrides ',xterm-256color:RGB'

      # Auto rename windows to directory
      set-option -g status-interval 1
      set-option -g automatic-rename on
      set-option -g automatic-rename-format ' #{b:pane_current_path}'

      run-shell ${pkgs.tmuxPlugins.cpu}/share/tmux-plugins/cpu/cpu.tmux
      run-shell ${pkgs.tmuxPlugins.battery}/share/tmux-plugins/battery/battery.tmux
    '';
  };
}
