# Dotfiles

Native application configuration shared between NixOS and other Linux hosts.

- `hyprland/hyprland.lua`: Hyprland + hy3 shortcuts and settings
- `nvim/`: Neovim Lua configuration (starter placeholder; import existing files)
- `kitty/`: Kitty terminal configuration (starter placeholder)

On NixOS, Home Manager creates **out-of-store symlinks** into this checkout.
Expected checkout: `~/nixos-config/dotfiles`.

Changes to these files are live; Hyprland typically reloads on save, while
some application changes require reloading or restarting the app. Nix rebuilds
are still needed for changes to packages or their integrations.

The hy3 binary is Nix-managed, with a stable link at
`~/.local/share/hyprland-plugins/libhy3.so`.

This directory is prepared for promotion to the public
`QuantxAmpere/dotfiles` Git submodule by `scripts/publish-dotfiles.sh`.
Do not add credentials or machine-specific secrets to it.
