# Repository Guidelines

## Project Structure & Module Organization
Configuration code lives in `hosts/<name>` with paired `configuration.nix` and `home.nix` files per machine. Shared modules sit in `darwin/`, `linux/`, and `home/`, while reusable packages are under `pkgs/`. Templates for new flakes are in `templates/`, assets in `backgrounds/`, and encrypted materials in `secrets/`. Treat `flake.nix` as the single entry point for wiring these pieces together.

## Build, Test, and Development Commands
Use `nix develop` (or `direnv allow`) to enter the devshell with pinned tooling. Build a host with `nix build .#darwinConfigurations.personal-laptop.system` or the matching `nixosConfigurations` target, then switch via `darwin-rebuild switch --flake .#personal-laptop` or `sudo nixos-rebuild switch --flake .#cicucci-server`. Run `nix flake check` before pushing to validate module evaluation and package builds.

## Coding Style & Naming Conventions
Format Nix code with `nix fmt` (treefmt + `nixpkgs-fmt`). Keep indentation at two spaces, sort attribute sets logically (systems first, then modules), and prefer explicit attribute names over aliases. Host folders use kebab-case (e.g., `cicucci-builder`), module files use snake_case when multiple variants exist, and secrets follow `<service>.age` under `secrets/`.

## Testing Guidelines
Rely on `nix flake check` for structural validation and run host builds for any machine you touch. When editing a module shared across platforms, compile at least one Darwin and one NixOS target (for example, `. #darwinConfigurations.work-laptop.system` and `. #nixosConfigurations.cicucci-dns.system`). Capture build output or failure logs in the pull request if tests expose regressions.

## Commit & Pull Request Guidelines
Follow the existing history: imperative, present-tense subjects (`Update ccusage`, `Add fd, sd, xh, and navi`). Keep commits scoped to a single concern and mention affected hosts in the body when relevant. Pull requests should summarize the intent, list tested commands, and link any related issues. Include screenshots only when UI-facing templates or assets change.

## Secrets & Configuration Safety
All sensitive values are managed through Agenix; edit them with `nix develop` and `agenix -e secrets/<file>.age`. Never commit decrypted secrets or machine-specific tokens. Confirm that new hosts reference existing age keys or document how to provision them.
