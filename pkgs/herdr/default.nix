{ lib
, stdenv
, rustPlatform
, fetchFromGitHub
, zig_0_15
, xcbuild
, cctools
, nix-update-script
,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "herdr";
  version = "0.5.8";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "ogulcancelik";
    repo = "herdr";
    tag = "v${finalAttrs.version}";
    hash = "sha256-nmFDcMmMhiklERIY2oPYqWqCPSzRWneHLawVtaxBZp0=";
  };

  cargoHash = "sha256-nU69jhqx0HkybH9UnTyJfYQ3JOe2dluUSNfXvO++G7M=";

  zigDeps = zig_0_15.fetchDeps {
    inherit (finalAttrs) pname version;
    src = "${finalAttrs.src}/vendor/libghostty-vt";
    fetchAll = true;
    hash = "sha256-GTbHRmgVjq1J4mbiZvsQa78tUKSn9afFDH85d3rQQ3o=";
  };

  nativeBuildInputs =
    [ zig_0_15.hook ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      xcbuild
      cctools
    ];

  # The Rust build only links zig-out/lib/libghostty-vt.a. In 0.5.8,
  # libghostty-vt auto-enables XCFramework output on Darwin when xcodebuild is
  # present, but nixpkgs' xcbuild does not support `-create-xcframework`.
  postPatch = lib.optionalString stdenv.hostPlatform.isDarwin ''
    substituteInPlace build.rs \
      --replace-fail '.arg("-Demit-lib-vt")' '.arg("-Demit-lib-vt").arg("-Demit-xcframework=false")'
  '';

  cargoTestFlags = [ "--bin=herdr" ];

  # These PTY foreground-process tests are sandbox-sensitive. Integration tests
  # are also skipped because they spawn Cargo's test binary path, which is not
  # present in buildRustPackage's check layout.
  checkFlags = [
    "--skip=detect::tests::foreground_job_detects_shell_running_command"
    "--skip=detect::tests::foreground_job_detects_sleep"
    "--skip=app::tests::reload_config_updates_sidebar_width_only_when_config_owned"
  ];

  dontUseZigBuild = true;
  dontUseZigCheck = true;
  dontUseZigInstall = true;

  postConfigure = ''
    export ZIG_GLOBAL_CACHE_DIR=$(mktemp -d)
    cp -rL ${finalAttrs.zigDeps} "$ZIG_GLOBAL_CACHE_DIR/p"
    chmod -R u+w "$ZIG_GLOBAL_CACHE_DIR/p"
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Agent multiplexer that lives in your terminal";
    homepage = "https://github.com/ogulcancelik/herdr";
    changelog = "https://github.com/ogulcancelik/herdr/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.agpl3Only;
    mainProgram = "herdr";
    platforms = lib.platforms.unix;
  };
})
