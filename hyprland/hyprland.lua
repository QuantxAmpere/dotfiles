-- Native Hyprland Lua config. Nix/Home Manager only installs and links it.
-- The plugin symlink is managed by home/hyprland.nix.

-- Remove the random splash text Hyprland draws at the bottom of the screen.
hl.config({ misc = { disable_splash_rendering = true } })

-- Cursor theme for the compositor, Xwayland and everything Hyprland spawns
-- (slurp draws the selection crosshair from these, so it must match or the
-- region picker shows the stock cursor). Same values as nixos-config's
-- XCURSOR_THEME and system-theme's gtk-cursor-theme-name.
hl.env('XCURSOR_THEME', 'Bibata-Original-Ice')
hl.env('XCURSOR_SIZE', '40')

-- Monitor rules are in a separate, live-editable file.
require('monitors/main')

-- Keyboard and pointer config are linked from dotfiles.
pcall(require, 'keyboard')
pcall(require, 'pointer')
local plugin = os.getenv('HOME') .. '/.local/share/hyprland-plugins/libhy3.so'

-- Plugin loading is declarative; Hyprland reloads Lua after it is available.
hl.plugin.load(plugin)

-- Hyprland 0.56.2 reports every kitty window as maximized on map, and kitty
-- then remembers that in ~/.cache/kitty/main.json, so every later window opens
-- maximized (full work area inside hy3). Upstream regression, gone in 0.56.1
-- behaviour; see hyprwm/Hyprland#16404 and kovidgoyal/kitty#10442. Drop this
-- rule once Hyprland no longer lies to clients.
hl.window_rule({
  match = { class = 'kitty' },
  fullscreen_state = '0 0',
})

-- Thunar opens as a fixed-size floating window, centered on the active monitor.
hl.window_rule({
  match = { class = 'thunar' },
  size = '1280 720',
  center = true,
  float = true,
})

-- Text clipboard history for the picker; images stay with wl-copy.
-- Guarded because this file also runs on `hyprctl reload`, where
-- hyprland.start does not fire, and a second watcher would double-store.
local function ensure_cliphist()
  hl.exec_cmd([[sh -c 'pgrep -x wl-paste >/dev/null || exec wl-paste --type text --watch cliphist store']])
end

hl.on('hyprland.start', function()
  hl.exec_cmd('kitty --class HeadlessKitty --single-instance --start-as=hidden tail -f /dev/null')
  -- Home Manager provides Waybar on local and headless sessions alike.
  hl.exec_cmd('waybar')
  ensure_cliphist()
end)

ensure_cliphist()

-- General shortcuts work even if hy3 is temporarily unavailable.
hl.bind('SUPER + Return', hl.dsp.exec_cmd('kitty'))
hl.bind('SUPER + SHIFT + Return', hl.dsp.exec_cmd('fuzzel'))
hl.bind('SUPER + Q', hl.dsp.window.close())
hl.bind('SUPER + M', hl.dsp.exit())

-- Floating lets you freely position a window outside hy3's tiling tree.
hl.bind('SUPER + F', hl.dsp.window.float({ action = 'toggle' }))
hl.bind('SUPER + G', hl.dsp.window.fullscreen({ mode = 'fullscreen', action = 'toggle' }))
hl.bind('SUPER + E', hl.dsp.exec_cmd('thunar'))

-- Monocle: float the active window as a centered 2/3 card on its monitor.
-- hy3 drops the node when a window floats, so unfloating re-inserts it next to
-- the focused node instead of its old slot. One monocle at a time: pinning
-- another window puts the previous one back into the layout first.
local monocle
local function monocle_restore(address)
  for _, window in ipairs(hl.get_windows()) do
    if window.address == address and window.floating then
      hl.dispatch(hl.dsp.window.float({ action = 'toggle', window = window }))
    end
  end
end

hl.bind('SUPER + K', function()
  local window = hl.get_active_window()
  if not window then return end

  if monocle == window.address and window.floating then
    monocle_restore(monocle)
    monocle = nil
    return
  end

  if monocle then monocle_restore(monocle) end

  local monitor = window.monitor
  if not monitor then return end

  if not window.floating then
    hl.dispatch(hl.dsp.window.float({ action = 'toggle', window = window }))
  end
  hl.dispatch(hl.dsp.window.resize({
    x = math.floor(monitor.width * 2 / 3),
    y = math.floor(monitor.height * 2 / 3),
    window = window,
  }))
  hl.dispatch(hl.dsp.window.center({ window = window }))
  monocle = window.address
end)

-- Multimedia keys: grab them here so apps don't receive raw key events.
hl.bind('XF86AudioMute', hl.dsp.exec_cmd('wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle'))
hl.bind('XF86AudioLowerVolume', hl.dsp.exec_cmd('wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%-'), { repeating = true })
hl.bind('XF86AudioRaiseVolume', hl.dsp.exec_cmd('wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+'), { repeating = true })

-- Region screenshot to ~/Pictures/Screenshots (timestamped) and the clipboard.
-- Plain Ctrl+V pastes it; the timestamp filename is what the picker shows.
hl.bind('SUPER + SHIFT + S',
  hl.dsp.exec_cmd(
  [[sh -c 'd="$HOME/Pictures/Screenshots"; mkdir -p "$d"; f="$d/$(date +%F_%H.%M.%S).png"; grim -g "$(slurp)" "$f" && wl-copy < "$f"']]))

-- Clipboard history: screenshots with timestamps, then copied text.
hl.bind('SHIFT + ALT + V', hl.dsp.exec_cmd('$HOME/.config/hypr/clip-pick.sh'))

-- Native mouse binds: move with Super + left drag, resize with Super + right drag.
-- For free positioning (rather than tiled layout behavior), float first with Super + F.
hl.bind('SUPER + mouse:272', hl.dsp.window.drag(), { mouse = true })
hl.bind('SUPER + mouse:273', hl.dsp.window.resize(), { mouse = true })

-- hy3 exposes its Lua dispatchers after the plugin loads.
if hl.plugin.hy3 then
  local hy3 = hl.plugin.hy3

  hl.config({
    general = { layout = 'hy3' },
    plugin = { hy3 = { node_collapse_policy = 0 } },
  })

  hl.bind('SUPER + T', hy3.change_group('toggletab'))
  hl.bind('SUPER + H', hy3.change_group('h'))
  hl.bind('SUPER + V', hy3.change_group('v'))
  hl.bind('SUPER + R', hy3.change_group('opposite'))

  hl.bind('SUPER + SHIFT + T', hy3.make_group('tab'))
  hl.bind('SUPER + SHIFT + H', hy3.make_group('h'))
  hl.bind('SUPER + SHIFT + V', hy3.make_group('v'))

  hl.bind('SUPER + left', hy3.move_focus('l'))
  hl.bind('SUPER + right', hy3.move_focus('r'))
  hl.bind('SUPER + up', hy3.move_focus('u'))
  hl.bind('SUPER + down', hy3.move_focus('d'))

  hl.bind('SUPER + SHIFT + left', hy3.move_window('l'))
  hl.bind('SUPER + SHIFT + right', hy3.move_window('r'))
  hl.bind('SUPER + SHIFT + up', hy3.move_window('u'))
  hl.bind('SUPER + SHIFT + down', hy3.move_window('d'))

  hl.bind('SUPER + A', hy3.change_focus('raise'))
  hl.bind('SUPER + Z', hy3.change_focus('lower'))
end

-- Numbered physical monitors and one-shot workspace selection submaps.
require('workspaces')







-- some styling

hl.config({
  decoration = {
    rounding = 10,
    rounding_power = 2.0,
  },
  general = {
    gaps_out = 34,
    gaps_in = 17
  },
})
