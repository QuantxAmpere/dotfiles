-- Independent remote Hyprland session (ma), nested under headless Weston.
-- HEADLESS-0 is shared by WayVNC and Sunshine (Moonlight).
-- The generic rule also covers the separate Weston-backed WAYLAND-* output.
hl.monitor({ output = '', mode = 'preferred', position = 'auto', scale = 1 })
hl.monitor({ output = 'HEADLESS-0', mode = '2560x1440@144', position = '0x0', scale = 1 })
