-- Framework i5-1240P: physical monitor or headless home server.
-- Prioritize the highest advertised refresh rate, even when that trades
-- resolution for Hz. Hyprland picks a supported mode for each monitor.
hl.monitor({ output = '', mode = 'highrr', position = 'auto', scale = 1 })

-- Default virtual display when Hyprland creates its fallback HEADLESS-0.
-- This does not create a virtual output or start a VNC server.
hl.monitor({ output = 'HEADLESS-0', mode = '2560x1440@60', position = '0x0', scale = 1 })
