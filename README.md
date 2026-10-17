# Dotfiles

Native application configuration shared between NixOS and other Linux hosts.

- `hyprland/hyprland.lua`: Hyprland + hy3 shortcuts and settings
- `nvim/`: Neovim Lua configuration (starter placeholder; import existing files)
- `kitty/`: Kitty terminal configuration (starter placeholder)

On NixOS, Home Manager creates **out-of-store symlinks** into this checkout.
Expected checkout: `~/dotfiles`.

Changes to these files are live; Hyprland typically reloads on save, while
some application changes require reloading or restarting the app. Nix rebuilds
are still needed for changes to packages or their integrations.

The hy3 binary is Nix-managed, with a stable link at
`~/.local/share/hyprland-plugins/libhy3.so`.

This is an independent public repository, cloned at `~/dotfiles` next to
`~/nixos-config`. Do not add credentials or machine-specific secrets.

## Hyprland window shortcuts

| Shortcut | Action |
| --- | --- |
| Super + F | Toggle floating for the focused window |
| Super + G | Toggle fullscreen for the focused window |
| Super + left mouse drag | Move the window under the pointer |
| Super + right mouse drag | Resize the window under the pointer |

Hy3 tiles windows by default. For freely dragging a window to an arbitrary
position, press Super + F to make it floating, then use Super + left drag.
Pull changes directly with `git -C ~/dotfiles pull --ff-only`.

## Monitor profiles

`hyprland.lua` loads `monitors/main.lua`, which chooses a profile using
`/etc/hostname`. Host-specific behavior is isolated in:

- `monitors/framework.lua` — highest available refresh rate on physical
  monitors, with a 2560x1440@60 rule for Hyprland's fallback headless output.
- `monitors/legion.lua` — native-resolution-first mode selection, hotplug,
  projector support, external-monitor arrangement and lid switching.

The resulting behavior:

- **Legion alone:** built-in panel at its highest-resolution/highest-refresh mode
  (normally 2560x1600@165).
- **Legion + projector:** internal panel and whatever external monitor is plugged
  in. Projectors are not forced to use the home-dock resolution.
- **Legion docked, lid closed:** disable the internal output if an external one
  exists. Position external displays left-to-right at each display's native
  resolution and highest refresh available at that resolution (normally
  3 x 2560x1440@144). Never disable the last active physical output.
- **Framework:** prioritize the highest supported refresh rate (`highrr`),
  including 2560x1440@144 when supported. Note that a lower-resolution,
  higher-Hz mode takes priority over a higher-resolution, lower-Hz mode.
- **Framework headless:** Hyprland's auto-created HEADLESS-0 uses
  2560x1440@60. No VNC service is started automatically yet.

The order of the Legion's three external screens currently defaults to connector
name order. Put actual connector names in `home_order` in `monitors/legion.lua`
after identifying which screen is physically left, center, and right.

Verify with `hyprctl monitors all` and `hyprctl configerrors`. Reload with
`hyprctl reload` after editing. To test laptop lid switches, first check
`hyprctl devices` for the actual switch name (expected `Lid Switch`).
The existing NixOS laptop power policy still controls whether closing the lid
suspends the machine.
