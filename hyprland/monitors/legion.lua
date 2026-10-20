-- Legion 5 Pro: internal screen, docked external displays, and projectors.
-- On hotplug, choose maximum resolution, then maximum refresh at that
-- resolution. Outputs are arranged left-to-right in connector order.
-- Set home_order below once the physical port identities are known.
-- Native 'highres' works on Hyprland 0.55 too (highest resolution, then
-- highest refresh). 'preferred' can select 60 Hz on the built-in panel.
-- Keep this as the initial/hotplug fallback; 0.56 additionally exposes
-- available_modes so the per-output logic below can refine the layout.
hl.monitor({ output = '', mode = 'highres', position = 'auto', scale = 1 })

-- On clickpads, libinput's bottom software-button zones can exclude fingers
-- from pinch recognition, turning some pinches into scroll/pointer motion.
-- Clickfinger uses finger count for physical clicks instead of bottom zones.
-- This affects only the Legion (this module is loaded by its host profile).
hl.config({ input = { touchpad = { clickfinger_behavior = true } } })

local home_order = {
    -- Fill with Legion's actual left/center/right connector names after
    -- checking `hyprctl monitors all`, for example: 'DP-2', 'DP-1', 'DP-3'.
}
local priority = {}
for i, output in ipairs(home_order) do priority[output] = i end

local function is_internal(name)
    return name:match('^eDP%-') ~= nil
end

local function is_virtual(name)
    return name:match('^HEADLESS%-') ~= nil or name == 'REMOTE'
end

local function best_mode(monitor)
    local best
    for _, mode in ipairs(monitor.available_modes or {}) do
        if mode.width and mode.height and mode.refresh_rate then
            local area = mode.width * mode.height
            if not best
                or area > best.width * best.height
                or (area == best.width * best.height and mode.refresh_rate > best.refresh_rate)
            then
                best = mode
            end
        end
    end
    if not best then
        -- Hyprland 0.55's Lua API has no available_modes. Use the compositor's
        -- built-in selector while keeping the current width for positioning.
        if not monitor.width or not monitor.height then return nil end
        return {
            width = monitor.width,
            height = monitor.height,
            refresh_rate = monitor.refresh_rate,
        }, 'highres'
    end
    return best, string.format('%dx%d@%.2f', best.width, best.height, best.refresh_rate)
end

local function lid_closed()
    -- ThinkPads/Legions commonly expose LID0; try other ACPI names as well.
    for _, lid in ipairs({ 'LID0', 'LID', 'LID1', 'LID2' }) do
        local file = io.open('/proc/acpi/button/lid/' .. lid .. '/state', 'r')
        if file then
            local state = file:read('*a')
            file:close()
            return state:match('closed') ~= nil
        end
    end
    return false
end

-- Disabled outputs are omitted from get_monitors() in Hyprland 0.55/0.56.
-- Remember the connector so opening the lid (or unplugging a dock) can
-- enable the panel again without requiring a restart.
local internal_name = nil
local lid_override = nil -- updated by lid switch events in this session
local function current_lid_state()
    if lid_override ~= nil then return lid_override end
    return lid_closed()
end

local function apply()
    local monitors = hl.get_monitors({ all = true })
    local internal, external = nil, {}

    for _, monitor in ipairs(monitors) do
        if is_internal(monitor.name) then
            internal = monitor
            internal_name = monitor.name
        elseif not is_virtual(monitor.name) then
            table.insert(external, monitor)
        end
    end

    table.sort(external, function(a, b)
        if (priority[a.name] or 1000) ~= (priority[b.name] or 1000) then
            return (priority[a.name] or 1000) < (priority[b.name] or 1000)
        end
        return a.name < b.name
    end)

    -- Keep an active screen if the lid is closed without any external output.
    -- This also recovers from unplugging a dock before opening the lid.
    local disable_internal = current_lid_state() and #external > 0
    local x = 0

    if not internal and internal_name and not disable_internal then
        -- Re-enable a previously disabled panel; a subsequent monitor.added
        -- event will reapply the complete layout with its actual dimensions.
        hl.monitor({ output = internal_name, mode = 'highres', position = '0x0', scale = 1, disabled = false })
    end

    if internal then
        if disable_internal then
            hl.monitor({ output = internal.name, disabled = true })
        else
            local mode, spec = best_mode(internal)
            if mode then
                local needs_update = internal.enabled == false
                    or internal.width ~= mode.width
                    or internal.height ~= mode.height
                    or math.abs(internal.refresh_rate - mode.refresh_rate) > 0.2
                    or internal.x ~= 0 or internal.y ~= 0 or math.abs(internal.scale - 1) > 0.01
                if needs_update then
                    hl.monitor({ output = internal.name, mode = spec, position = '0x0', scale = 1, disabled = false })
                end
                x = mode.width
            end
        end
    end

    for _, monitor in ipairs(external) do
        local mode, spec = best_mode(monitor)
        if mode then
            local target_position = string.format('%dx0', x)
            local needs_update = monitor.enabled == false
                or monitor.width ~= mode.width
                or monitor.height ~= mode.height
                or math.abs(monitor.refresh_rate - mode.refresh_rate) > 0.2
                or monitor.x ~= x or monitor.y ~= 0 or math.abs(monitor.scale - 1) > 0.01
            if needs_update then
                hl.monitor({ output = monitor.name, mode = spec, position = target_position, scale = 1, disabled = false })
            end
            x = x + mode.width
        end
    end
end

-- Changing monitor rules emits more monitor events. Debounce them; apply()
-- does nothing when active modes, positions, and enabled states already match.
local pending
local function schedule()
    if pending then pending:set_enabled(false) end
    pending = hl.timer(function()
        pending = nil
        apply()
    end, { timeout = 300, type = 'oneshot' })
end

hl.on('hyprland.start', schedule)
hl.on('monitor.added', schedule)
hl.on('monitor.removed', schedule)
-- Do not react to layout_changed: our own mode updates trigger it.

-- The switch name is hardware-dependent: inspect `hyprctl devices`.
hl.bind('switch:on:Lid Switch', function()
    lid_override = true
    schedule()
end, { locked = true })
hl.bind('switch:off:Lid Switch', function()
    lid_override = false
    schedule()
end, { locked = true })
