return client.delay_call(0.1, function()
    local pitch = ui.reference('AA', 'Anti-aimbot angles', 'Pitch')
    local enabled = ui.reference('AA', 'Anti-aimbot angles', 'Enabled')
    
    local g_cache = nil
    local g_reset = function()
        if g_cache ~= nil then
            ui.set(enabled, g_cache)
            g_cache = nil
        end
    end

    client.set_event_callback('shutdown', g_reset)
    client.set_event_callback('run_command', g_reset)
    client.set_event_callback('setup_command', function()
        g_reset()

        local me = entity.get_local_player()
        local m_vecvel = { entity.get_prop(me, 'm_vecVelocity') }

        if math.floor(math.sqrt(m_vecvel[1]^2 + m_vecvel[2]^2 + m_vecvel[3]^2) + 0.5) > 1 then
            g_cache = ui.get(enabled)
            ui.set(enabled, false)
        end
    end)
end)
