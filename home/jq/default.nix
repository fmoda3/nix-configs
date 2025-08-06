{
  programs.jq = {
    enable = true;
    colors = {
      null = "2;37"; # Dim white - subtle like Frappe overlay colors
      false = "0;31"; # Red - Frappe red #e78284
      true = "0;32"; # Green - Frappe green #a6d189  
      numbers = "0;33"; # Yellow - Frappe yellow #e5c890
      strings = "0;36"; # Cyan - representing Frappe teal #81c8be
      arrays = "1;34"; # Bright blue - Frappe blue #8caaee
      objects = "1;37"; # Bright white - Frappe text color #c6d0f5
      objectKeys = "1;35"; # Bright magenta - Frappe mauve #ca9ee6
    };
  };
}
