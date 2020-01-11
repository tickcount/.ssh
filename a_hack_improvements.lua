local ui_get, ui_set = ui.get, ui.set

local ffi_ref = {
    team = ui.reference('Visuals', 'Player ESP', 'Teammates'),

    slowmotion = { ui.reference('AA', 'Other', 'Slow motion') },
    airstrafe = ui.reference('MISC', 'Movement', 'Air strafe'),
    onshot_aa = { ui.reference('AA', 'Other', 'On shot anti-aim') },
    usercmd_holdaim = ui.reference('MISC', 'Settings', 'sv_maxusrcmdprocessticks_holdaim'),
}

-- Functions
local ffi_cache = { }
local invoke_cache = function(condition, should_call, a, b) local name = tostring(condition); ffi_cache[name] = ffi_cache[name] or ui.get(condition); if should_call then if type(a) == 'function' then a() else ui.set(condition, a); end else if ffi_cache[name] ~= nil then if b ~= nil and type(b) == 'function' then b(ffi_cache[name]); else ui.set(condition, ffi_cache[name]); end ffi_cache[name] = nil; end end end

local function get_entities(enemy_only, alive_only)
    local enemy_only = enemy_only ~= nil and enemy_only or false
    local alive_only = alive_only ~= nil and alive_only or true
    
    local result = {}
    
    local e_get_prop = entity.get_prop
    local player_resource = entity.get_player_resource()
    
    for player = 1, globals.maxplayers() do
        if e_get_prop(player_resource, 'm_bConnected', player) == 1 then
            local is_enemy, is_alive = true, true
            
            if enemy_only and not entity.is_enemy(player) then is_enemy = false end
            if is_enemy then
                if alive_only and e_get_prop(player_resource, 'm_bAlive', player) ~= 1 then is_alive = false end
                if is_alive then table.insert(result, player) end
            end
        end
    end

    return result
end

local invoke_esp = function()
    local players = get_entities(not ui.get(ffi_ref.team), true)

    if #players == 0 then
        return
    end

    for i=1, #players do
        local player = players[i]
        local _, _, _, _, state = entity.get_bounding_box(c, player)

        local alive = entity.is_alive(player) and not entity.is_dormant(player)
        local health = entity.get_prop(player, 'm_iHealth')

        if state > 0.0000 and alive and health <= 0 and dormant then
            entity.set_prop(player, 'm_iHealth', 100)
        end
    end
end

local user_cmd = function(e)
    if ui_get(ffi_ref.onshot_aa[1]) then 
        ui_set(ffi_ref.usercmd_holdaim, true)
    end

    local in_speed = e.in_speed == 1
    local in_slowmo = ui_get(ffi_ref.slowmotion[1]) and ui_get(ffi_ref.slowmotion[2])

    if in_speed and in_slowmo then
        e.in_speed = 0
    end

    local me = entity.get_local_player()
    local wpn = entity.get_player_weapon(me)

    if wpn ~= nil and entity.get_classname(wpn) == 'CC4' then
        if e.in_attack == 1 then
            e.in_attack = 0
            e.in_use = 1
        end
    end

    invoke_cache(ffi_ref.airstrafe, in_speed, false)
end

local shutdown = function()
    invoke_cache(ffi_ref.airstrafe, false)
end

client.set_event_callback('paint', invoke_esp)
client.set_event_callback('setup_command', user_cmd)
client.set_event_callback('shutdown', shutdown)
