-- Native Hyprland Lua config. Nix/Home Manager only installs and links it.
-- The plugin symlink is managed by home/hyprland.nix.

-- Remove the random splash text Hyprland draws at the bottom of the screen.
hl.config({ misc = { disable_splash_rendering = true } })

-- Monitor rules are in a separate, live-editable file.
require('monitors/main')

-- Keyboard and pointer config are linked from dotfiles.
pcall(require, 'keyboard')
pcall(require, 'pointer')
local plugin = os.getenv('HOME') .. '/.local/share/hyprland-plugins/libhy3.so'

-- Plugin loading is declarative; Hyprland reloads Lua after it is available.
hl.plugin.load(plugin)

hl.on('hyprland.start', function()
    hl.exec_cmd('kitty --class HeadlessKitty --single-instance --start-as=hidden tail -f /dev/null')
    -- Home Manager provides Waybar on local and headless sessions alike.
    hl.exec_cmd('waybar')
end)

-- General shortcuts work even if hy3 is temporarily unavailable.
hl.bind('SUPER + Return', hl.dsp.exec_cmd('kitty --single-instance'))
hl.bind('SUPER + SHIFT + Return', hl.dsp.exec_cmd('fuzzel'))
hl.bind('SUPER + Q', hl.dsp.window.close())
hl.bind('SUPER + M', hl.dsp.exit())

-- Floating lets you freely position a window outside hy3's tiling tree.
hl.bind('SUPER + F', hl.dsp.window.float({ action = 'toggle' }))
hl.bind('SUPER + G', hl.dsp.window.fullscreen({ mode = 'fullscreen', action = 'toggle' }))

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
    }
})





