{ lib, ... }:
{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
    enableTransience = true;
    settings = {
      palette = "catppuccin_frappe";
      palettes = {
        catppuccin_frappe = {
          background = "#303446";
          foreground = "#c6d0f5";
          black = "#51576d";
          red = "#e78284";
          green = "#a6d189";
          yellow = "#e5c890";
          blue = "#8caaee";
          purple = "#ca9ee6";
          cyan = "#81c8be";
          white = "#c6d0f5";
          bright-black = "#626880";
          bright-red = "#e78284";
          bright-green = "#a6d189";
          bright-yellow = "#e5c890";
          bright-blue = "#8caaee";
          bright-purple = "#ca9ee6";
          bright-cyan = "#99d1db";
          bright-white = "#f2d5cf";
          dark_gray = "#737994";
          light_gray = "#949cbb";
          orange = "#ef9f76";
        };
      };
      format = lib.concatStrings [
        "$username"
        "$hostname"
        "$localip"
        "$shlvl"
        "$singularity"
        "$kubernetes"
        "$directory"
        "$vcsh"
        "$fossil_branch"
        "$fossil_metrics"
        "$git_branch"
        "$git_commit"
        "$git_state"
        "$git_metrics"
        "$git_status"
        "$hg_branch"
        "$pijul_channel"
        "$docker_context"
        "$package"
        "$c"
        "$cmake"
        "$cobol"
        "$daml"
        "$dart"
        "$deno"
        "$dotnet"
        "$elixir"
        "\${custom.elixir}"
        "$elm"
        "$erlang"
        "$fennel"
        "$gleam"
        "$golang"
        "$guix_shell"
        "$haskell"
        "$haxe"
        "$helm"
        "$java"
        "$julia"
        "$kotlin"
        "$gradle"
        "$lua"
        "$nim"
        "$nodejs"
        "$ocaml"
        "$opa"
        "$perl"
        "$php"
        "$pulumi"
        "$purescript"
        "$python"
        "$quarto"
        "$raku"
        "$rlang"
        "$red"
        "$ruby"
        "$rust"
        "$scala"
        "$solidity"
        "$swift"
        "$terraform"
        "$typst"
        "$vlang"
        "$vagrant"
        "$zig"
        "$buf"
        "$nix_shell"
        "$conda"
        "$meson"
        "$spack"
        "$memory_usage"
        "$aws"
        "$gcloud"
        "$openstack"
        "$azure"
        "$nats"
        "$direnv"
        "$env_var"
        "$crystal"
        "$custom"
        "$sudo"
        "$cmd_duration"
        "$line_break"
        "$jobs"
        "$battery"
        "$time"
        "$status"
        "$os"
        "$container"
        "$shell"
        "$character"
      ];
      aws = {
        disabled = true;
        symbol = "  ";
        format = "\\[[$symbol($profile)(\\($region\))(\\[$duration\\])]($style)\\]";
      };
      bun = {
        format = "\\[[$symbol($version)]($style)\\]";
      };
      buf = {
        symbol = " ";
      };
      c = {
        symbol = " ";
        format = "\\[[$symbol($version(-$name))]($style)\\]";
      };
      cmake = {
        symbol = " ";
        format = "\\[[$symbol($version)]($style)\\]";
      };
      cmd_duration = {
        format = "\\[[⏱ $duration]($style)\\]";
      };
      cobol = {
        format = "\\[[$symbol($version)]($style)\\]";
      };
      conda = {
        symbol = " ";
        format = "\\[[$symbol$environment]($style)\\]";
      };
      crystal = {
        symbol = " ";
        format = "\\[[$symbol($version)]($style)\\]";
      };
      daml = {
        format = "\\[[$symbol($version)]($style)\\]";
      };
      dart = {
        symbol = " ";
        format = "\\[[$symbol($version)]($style)\\]";
      };
      deno = {
        format = "\\[[$symbol($version)]($style)\\]";
      };
      directory = {
        read_only = " 󰌾";
      };
      direnv = {
        disabled = false;
        format = "\\[[$symbol$loaded/$allowed]($style)\\]";
      };
      docker_context = {
        disabled = true;
        symbol = " ";
        format = "\\[[$symbol$context]($style)\\]";
      };
      dotnet = {
        format = "\\[[$symbol($version)(🎯 $tfm)]($style)\\]";
      };
      custom.elixir = {
        command = "elixir --short-version";
        detect_files = [ "mix.exs" ];
        symbol = " ";
        format = "\\[[$symbol($output)]($style)\\]";
        style = "bold purple";
      };
      elixir = {
        disabled = true;
        symbol = " ";
        format = "\\[[$symbol($version \\(OTP $otp_version\\))]($style)\\]";
      };
      elm = {
        symbol = " ";
        format = "\\[[$symbol($version)]($style)\\]";
      };
      erlang = {
        format = "\\[[$symbol($version)]($style)\\]";
      };
      fennel = {
        symbol = " ";
        format = "\\[[$symbol($version)]($style)\\]";
      };
      fossil_branch = {
        symbol = " ";
        format = "\\[[$symbol$branch]($style)\\]";
      };
      gcloud = {
        format = "\\[[$symbol$account(@$domain)(\\($region\\))]($style)\\]";
      };
      git_branch = {
        symbol = " ";
        format = "\\[[$symbol$branch]($style)\\]";
      };
      git_commit = {
        tag_symbol = "  ";
      };
      git_status = {
        stashed = "";
        format = "([\\[$all_status$ahead_behind\\]]($style))";
      };
      golang = {
        symbol = " ";
        format = "\\[[$symbol($version)]($style)\\]";
      };
      gradle = {
        symbol = " ";
        format = "\\[[$symbol($version)]($style)\\]";
      };
      guix_shell = {
        symbol = " ";
        format = "\\[[$symbol]($style)\\]";
      };
      haskell = {
        symbol = " ";
        format = "\\[[$symbol($version)]($style)\\]";
      };
      haxe = {
        symbol = " ";
        format = "\\[[$symbol($version)]($style)\\]";
      };
      helm = {
        format = "\\[[$symbol($version)]($style)\\]";
      };
      hg_branch = {
        symbol = " ";
        format = "\\[[$symbol$branch]($style)\\]";
      };
      hostname = {
        ssh_symbol = " ";
      };
      java = {
        symbol = " ";
        format = "\\[[$symbol($version)]($style)\\]";
      };
      julia = {
        symbol = " ";
        format = "\\[[$symbol($version)]($style)\\]";
      };
      kotlin = {
        symbol = " ";
        format = "\\[[$symbol($version)]($style)\\]";
      };
      kubernetes = {
        format = "\\[[$symbol$context( \\($namespace\\))]($style)\\]";
      };
      lua = {
        symbol = " ";
        format = "\\[[$symbol($version)]($style)\\]";
      };
      memory_usage = {
        symbol = "󰍛 ";
        format = "\\[$symbol[$ram( | $swap)]($style)\\]";
      };
      meson = {
        symbol = "󰔷 ";
        format = "\\[[$symbol$project]($style)\\]";
      };
      nim = {
        symbol = "󰆥 ";
        format = "\\[[$symbol($version)]($style)\\]";
      };
      nix_shell = {
        symbol = " ";
        format = "\\[[$symbol$state( \\($name\\))]($style)\\]";
      };
      nodejs = {
        symbol = " ";
        format = "\\[[$symbol($version)]($style)\\]";
      };
      ocaml = {
        symbol = " ";
        format = "\\[[$symbol($version)(\\($switch_indicator$switch_name\\))]($style)\\]";
      };
      opa = {
        format = "\\[[$symbol($version)]($style)\\]";
      };
      openstack = {
        format = "\\[[$symbol$cloud(\\($project\\))]($style)\\]";
      };
      os = {
        symbols = {
          Alpaquita = " ";
          Alpine = " ";
          AlmaLinux = " ";
          Amazon = " ";
          Android = " ";
          Arch = " ";
          Artix = " ";
          CachyOS = " ";
          CentOS = " ";
          Debian = " ";
          DragonFly = " ";
          Emscripten = " ";
          EndeavourOS = " ";
          Fedora = " ";
          FreeBSD = " ";
          Garuda = "﯑ ";
          Gentoo = " ";
          HardenedBSD = "󰞌 ";
          Illumos = "󰈸 ";
          Kali = " ";
          Linux = " ";
          Mabox = " ";
          Macos = " ";
          Manjaro = " ";
          Mariner = " ";
          MidnightBSD = " ";
          Mint = " ";
          NetBSD = " ";
          NixOS = " ";
          Nobara = " ";
          OpenBSD = "󰈺 ";
          openSUSE = " ";
          OracleLinux = "󰌷 ";
          Pop = " ";
          Raspbian = " ";
          Redhat = " ";
          RedHatEnterprise = " ";
          RockyLinux = " ";
          Redox = "󰀘 ";
          Solus = "󰠳 ";
          SUSE = " ";
          Ubuntu = " ";
          Unknown = " ";
          Void = " ";
          Windows = "󰍲 ";
        };
        format = "\\[[$symbol]($style)\\]";
      };
      package = {
        disabled = true;
        symbol = "󰏗 ";
        format = "\\[[$symbol$version]($style)\\]";
      };
      perl = {
        symbol = " ";
        format = "\\[[$symbol($version)]($style)\\]";
      };
      php = {
        symbol = " ";
        format = "\\[[$symbol($version)]($style)\\]";
      };
      pijul_channel = {
        symbol = " ";
        format = "\\[[$symbol$channel]($style)\\]";
      };
      pulumi = {
        format = "\\[[$symbol$stack]($style)\\]";
      };
      purescript = {
        format = "\\[[$symbol($version)]($style)\\]";
      };
      python = {
        symbol = " ";
        format = "\\[[\${symbol}\${pyenv_prefix}(\${version})(\\($virtualenv\\))]($style)\\]";
      };
      raku = {
        format = "\\[[$symbol($version-$vm_version)]($style)\\]";
      };
      red = {
        format = "\\[[$symbol($version)]($style)\\]";
      };
      rlang = {
        symbol = "󰟔 ";
      };
      ruby = {
        symbol = " ";
        format = "\\[[$symbol($version)]($style)\\]";
      };
      rust = {
        symbol = " ";
        format = "\\[[$symbol($version)]($style)\\]";
      };
      scala = {
        symbol = " ";
        format = "\\[[$symbol($version)]($style)\\]";
      };
      spack = {
        symbol = "🅢 ";
        format = "\\[[$symbol$environment]($style)\\]";
      };
      solidity = {
        format = "\\[[$symbol($version)]($style)\\]";
      };
      sudo = {
        format = "\\[[as $symbol]($style)\\]";
      };
      swift = {
        symbol = " ";
        format = "\\[[$symbol($version)]($style)\\]";
      };
      terraform = {
        format = "\\[[$symbol$workspace]($style)\\]";
      };
      time = {
        format = "\\[[$time]($style)\\]";
      };
      username = {
        format = "\\[[$user]($style)\\]";
      };
      vagrant = {
        format = "\\[[$symbol($version)]($style)\\]";
      };
      vlang = {
        format = "\\[[$symbol($version)]($style)\\]";
      };
      zig = {
        symbol = " ";
        format = "\\[[$symbol($version)]($style)\\]";
      };
    };
  };
}
