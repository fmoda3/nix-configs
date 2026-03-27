{ lib
, stdenv
, callPackage
, rustPlatform
, fetchFromGitHub
, installShellFiles
, cargo
, clang
, cmake
, gitMinimal
, libcap
, libclang
, librusty_v8 ? callPackage ./librusty_v8.nix {
    inherit (callPackage ./fetchers.nix { }) fetchLibrustyV8;
  }
, makeBinaryWrapper
, nix-update-script
, pkg-config
, openssl
, ripgrep
, versionCheckHook
, installShellCompletions ? stdenv.buildPlatform.canExecute stdenv.hostPlatform
,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "codex";
  version = "0.117.0";

  src = fetchFromGitHub {
    owner = "openai";
    repo = "codex";
    tag = "rust-v${finalAttrs.version}";
    hash = "sha256-Ezd8KaEMVeJPKC74CSPhecPLZghm0v6JkQTCPhr/2nY=";
  };

  sourceRoot = "${finalAttrs.src.name}/codex-rs";

  # TODO: Drop workaround once PR #486983 reaches master.
  depsExtraArgs = {
    nativeBuildInputs = [ cargo ];
    postBuild = ''
      # delete all Cargo.toml files for which `cargo metadata` fails
      shopt -s globstar
      for manifest_path in "$out"/**/Cargo.toml; do
        cargo metadata --format-version 1 --no-deps --manifest-path "$manifest_path" >/dev/null || rm -v "$manifest_path"
      done
    '';
  };

  cargoHash = "sha256-QUh2G35uIUlQnq4LVt+TVs8hAf+3fo1WULpPWtw2Uxs=";

  nativeBuildInputs = [
    clang
    cmake
    gitMinimal
    installShellFiles
    makeBinaryWrapper
    pkg-config
  ];

  buildInputs = [
    libclang
    openssl
  ] ++ lib.optionals stdenv.hostPlatform.isLinux [
    libcap
  ];

  # NOTE: set LIBCLANG_PATH so bindgen can locate libclang, and adjust
  # warning-as-error flags to avoid known false positives (GCC's
  # stringop-overflow in BoringSSL's a_bitstr.cc) while keeping Clang's
  # character-conversion warning-as-error disabled.
  env = {
    LIBCLANG_PATH = "${lib.getLib libclang}/lib";
    NIX_CFLAGS_COMPILE = toString (
      lib.optionals stdenv.cc.isGNU [
        "-Wno-error=stringop-overflow"
      ]
      ++ lib.optionals stdenv.cc.isClang [
        "-Wno-error=character-conversion"
      ]
    );
    RUSTY_V8_ARCHIVE = librusty_v8;
  };

  # NOTE: part of the test suite requires access to networking, local shells,
  # apple system configuration, etc. since this is a very fast moving target
  # (for now), with releases happening every other day, constantly figuring out
  # which tests need to be skipped, or finding workarounds, was too burdensome,
  # and in practice not adding any real value. this decision may be reversed in
  # the future once this software stabilizes.
  doCheck = false;

  postInstall = lib.optionalString installShellCompletions ''
    installShellCompletion --cmd codex \
      --bash <($out/bin/codex completion bash) \
      --fish <($out/bin/codex completion fish) \
      --zsh <($out/bin/codex completion zsh)
  '';

  postFixup = ''
    wrapProgram $out/bin/codex --prefix PATH : ${lib.makeBinPath [ ripgrep ]}
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];

  passthru = {
    updateScript = nix-update-script {
      extraArgs = [
        "--version-regex"
        "^rust-v(\\d+\\.\\d+\\.\\d+)$"
      ];
    };
  };

  meta = {
    description = "Lightweight coding agent that runs in your terminal";
    homepage = "https://github.com/openai/codex";
    changelog = "https://raw.githubusercontent.com/openai/codex/refs/tags/rust-v${finalAttrs.version}/CHANGELOG.md";
    license = lib.licenses.asl20;
    mainProgram = "codex";
    platforms = lib.platforms.unix;
  };
})
