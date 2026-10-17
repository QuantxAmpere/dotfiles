-- Framework i5-1240P: physical monitor or headless home server.
-- Prefer the highest supported resolution, then the highest refresh rate
-- at that resolution (e.g. 2560x1440@144 over 1920x1080@165).
hl.monitor({ output = '', mode = 'highres', position = 'auto', scale = 1 })

-- Default virtual display when Hyprland creates its fallback HEADLESS-0.
-- This does not create a virtual output or start a VNC server.
hl.monitor({ output = 'HEADLESS-0', mode = '2560x1440@60', position = '0x0', scale = 1 })
