-- Load only the monitor profile for this host.
local file = io.open('/etc/hostname', 'r')
local hostname = file and file:read('*l') or os.getenv('HOSTNAME')
if file then file:close() end

local profiles = {
    framework = 'monitors/framework',
    legion = 'monitors/legion',
}

local profile = profiles[hostname]
if profile then
    require(profile)
else
    -- Safe fallback for other machines using these public dotfiles.
    hl.monitor({ output = '', mode = 'preferred', position = 'auto', scale = 1 })
end
