-- Independent remote Hyprland session (ma), nested under headless Weston.
-- HEADLESS-0 is created by the NixOS systemd service and captured by WayVNC.
-- The generic rule also covers the separate Weston-backed WAYLAND-* output.
hl.monitor({ output = '', mode = 'preferred', position = 'auto', scale = 1 })
hl.monitor({ output = 'HEADLESS-0', mode = '1920x1080@30', position = '0x0', scale = 1 })
