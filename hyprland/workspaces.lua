-- Four logical monitors, nine workspaces each. Workspace 35 is monitor 3,
-- workspace 5. We delegate dynamic monitor discovery to a short-lived helper,
-- never blocking Hyprland's Lua event loop with subprocess calls.
local script = os.getenv('HOME') .. '/.config/hypr/workspaces.py'
local function run(action, monitor, digit)
    local command = 'python3 ' .. script .. ' ' .. action
    if monitor then command = command .. ' ' .. monitor end
    if digit then command = command .. ' ' .. digit end
    hl.exec_cmd(command)
end

for monitor = 1, 4 do
    hl.bind('SUPER + ' .. monitor, function()
        run('focus-monitor', monitor)
    end)
    hl.bind('SUPER + SHIFT + ' .. monitor, function()
        run('move-monitor', monitor)
    end)
end

hl.bind('SUPER + W', hl.dsp.submap('workspace_monitors'))

hl.define_submap('workspace_monitors', function()
    for monitor = 1, 4 do
        hl.bind(tostring(monitor), hl.dsp.submap('workspace_digits_' .. monitor))
        -- Shift on either digit (or on both) means move, not follow.
        hl.bind('SHIFT + ' .. monitor, hl.dsp.submap('workspace_move_digits_' .. monitor))
    end
    hl.bind('escape', hl.dsp.submap('reset'))
    -- No catchall here: Hyprland queues it next to the digit bind and
    -- immediately resets the submap the digit just entered.
end)

for monitor = 1, 4 do
    hl.define_submap('workspace_digits_' .. monitor, 'reset', function()
        for digit = 1, 9 do
            hl.bind(tostring(digit), function()
                run('focus-workspace', monitor, digit)
            end)
            hl.bind('SHIFT + ' .. digit, function()
                run('move-workspace', monitor, digit)
            end)
        end
        hl.bind('escape', hl.dsp.submap('reset'))
        hl.bind('catchall', hl.dsp.submap('reset'))
    end)

    hl.define_submap('workspace_move_digits_' .. monitor, 'reset', function()
        for digit = 1, 9 do
            hl.bind(tostring(digit), function()
                run('move-workspace', monitor, digit)
            end)
            hl.bind('SHIFT + ' .. digit, function()
                run('move-workspace', monitor, digit)
            end)
        end
        hl.bind('escape', hl.dsp.submap('reset'))
        hl.bind('catchall', hl.dsp.submap('reset'))
    end)
end

-- The Legion's monitor profile separately debounces physical layout changes.
-- Sync a little later so we see the final positions, not interim modes.
local pending
local function schedule_sync()
    if pending then pending:set_enabled(false) end
    pending = hl.timer(function()
        pending = nil
        run('sync')
    end, { timeout = 900, type = 'oneshot' })
end
hl.on('hyprland.start', schedule_sync)
hl.on('monitor.added', schedule_sync)
hl.on('monitor.removed', schedule_sync)
