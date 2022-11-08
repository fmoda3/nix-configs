{ config, pkgs, lib, ... }:
{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      format = lib.concatStrings [
        "$username"
        "$hostname"
        "$localip"
        "$shlvl"
        "$singularity"
        "$kubernetes"
        "$directory"
        "$vcsh"
        "$git_branch"
        "$git_commit"
        "$git_state"
        "$git_metrics"
        "$git_status"
        "$hg_branch"
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
        "$golang"
        "$haskell"
        "$helm"
        "$java"
        "$julia"
        "$kotlin"
        "$lua"
        "$nim"
        "$nodejs"
        "$ocaml"
        "$perl"
        "$php"
        "$pulumi"
        "$purescript"
        "$python"
        "$raku"
        "$rlang"
        "$red"
        "$ruby"
        "$rust"
        "$scala"
        "$swift"
        "$terraform"
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
        format = "\\[[$symbol($version)]($style)\\]";
      };
      cmd_duration = {
        format = "\\[[$duration]($style)\\]";
      };
      cobol = {
        format = "\\[[$symbol($version)]($style)\\]";
      };
      conda = {
        symbol = " ";
        format = "\\[[$symbol$environment]($style)\\]";
      };
      crystal = {
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
        read_only = " ";
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
      gcloud = {
        format = "\\[[$symbol$account(@$domain)(\\($region\\))]($style)\\]";
      };
      git_branch = {
        symbol = " ";
        format = "\\[[$symbol$branch]($style)\\]";
      };
      git_status = {
        stashed = "";
        format = "([\\[$all_status$ahead_behind\\]]($style))";
      };
      golang = {
        symbol = " ";
        format = "\\[[$symbol($version)]($style)\\]";
      };
      haskell = {
        symbol = " ";
        format = "\\[[$symbol($version)]($style)\\]";
      };
      helm = {
        format = "\\[[$symbol($version)]($style)\\]";
      };
      hg_branch = {
        symbol = " ";
        format = "\\[[$symbol$branch]($style)\\]";
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
        symbol = " ";
        format = "\\[$symbol[$ram( | $swap)]($style)\\]";
      };
      meson = {
        symbol = "喝 ";
        format = "\\[[$symbol$project]($style)\\]";
      };
      nim = {
        symbol = " ";
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
        format = "\\[[$symbol($version)(\\($switch_indicator$switch_name\\))]($style)\\]";
      };
      openstack = {
        format = "\\[[$symbol$cloud(\\($project\\))]($style)\\]";
      };
      package = {
        disabled = true;
        symbol = " ";
        format = "\\[[$symbol$version]($style)\\]";
      };
      perl = {
        format = "\\[[$symbol($version)]($style)\\]";
      };
      php = {
        format = "\\[[$symbol($version)]($style)\\]";
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
        symbol = "ﳒ ";
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
      sudo = {
        format = "\\[[as $symbol]\\]";
      };
      swift = {
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
        format = "\\[[$symbol($version)]($style)\\]";
      };
    };
  };
}
