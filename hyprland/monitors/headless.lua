-- Remote-only Hyprland session (ma, not ma-local).
-- Aquamarine's render-only backend should create a fallback HEADLESS-0.
-- Never configure physical connectors in this process.
hl.monitor({ output = '', mode = 'preferred', position = 'auto', scale = 1 })
hl.monitor({ output = 'HEADLESS-0', mode = '2560x1440@60', position = '0x0', scale = 1 })
