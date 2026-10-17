-- Load only the monitor profile for this host.
local file = io.open('/etc/hostname', 'r')
local hostname = file and file:read('*l') or os.getenv('HOSTNAME')
if file then file:close() end

local profiles = {
    framework = 'monitors/framework',
    legion = 'monitors/legion',
}

-- The dedicated VNC compositor is headless even though its host is framework.
-- Its systemd service sets this flag; ma-local does not.
local profile = os.getenv('HYPRLAND_REMOTE_SESSION') == '1'
    and 'monitors/headless'
    or profiles[hostname]
if profile then
    require(profile)
else
    -- Safe fallback for other machines using these public dotfiles.
    hl.monitor({ output = '', mode = 'preferred', position = 'auto', scale = 1 })
end
