self: super:
{
  yabai = super.yabai.overrideAttrs (o: rec {
    version = "3.3.7";
    src = builtins.fetchTarball {
      url = "https://github.com/koekeishiya/yabai/releases/download/v${version}/yabai-v${version}.tar.gz";
      sha256 = "1ywccgqajyqb8pqaxap2dci6wy2jba6snrzsiawdmnbvv1bsp3z2";
    };

    installPhase = ''
      mkdir -p $out/bin
      mkdir -p $out/share/man/man1/
      cp ./archive/bin/yabai $out/bin/yabai
      cp ./archive/doc/yabai.1 $out/share/man/man1/yabai.1
    '';
  });
}
