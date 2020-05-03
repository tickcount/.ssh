local player_list = ui.reference('PLAYERS', 'Players', 'Player list')
local pl_reset = ui.reference('PLAYERS', 'Players', 'Reset all')

local or_cactive = ui.reference('PLAYERS', 'Adjustments', 'Correction active')

local or_acb = ui.reference('PLAYERS', 'Adjustments', 'Override accuracy boost')
local or_baim = ui.reference('PLAYERS', 'Adjustments', 'Override prefer body aim')
local or_spoint = ui.reference('PLAYERS', 'Adjustments', 'Override safe point')

local or_prefer_baim = ui.reference('RAGE', 'Other', 'Prefer body aim')
local or_prefer_baim_disablers = ui.reference('RAGE', 'Other', 'Prefer body aim disablers')

local shared_esp = ui.reference('VISUALS', 'Other ESP', 'Shared ESP')
local restrict_shared_esp = ui.reference('VISUALS', 'Other ESP', 'Restrict shared ESP updates')

local fake_duck = ui.reference('RAGE', 'Other', 'Duck peek assist')

-- menu
local ui_get, ui_set = ui.get, ui.set
local entity_get_prop = entity.get_prop

local contains = function(tab, val) for i = 1, #tab do if tab[i] == val then return true; end end; return false end
local el = {
    prefer_head = { 'Target shot fired', 'In air', 'Is crouching', 'Is walking', 'Backwards/Forwards', 'Sideways' },
    prefer_body = { 'Force condition', 'Target shot fired', 'In air', 'Is crouching', 'Is walking', 'Backwards/Forwards', 'Sideways', '2 Shots', 'Lethal', '<x HP', 'Correction active', --[[ 'Big desync range', 'Jitter desync' ]] },
}

local player_data = { }
local functions = {
    normalize_yaw = function(yaw)
        while yaw > 180 do yaw = yaw - 360 end
        while yaw < -180 do yaw = yaw + 360 end

        return yaw
    end,

    angle_to_vec = function(pitch, yaw)
        local deg2rad = math.pi / 180.0
        
        local p, y = deg2rad*pitch, deg2rad*yaw
        local sp, cp, sy, cy = sin(p), cos(p), sin(y), cos(y)
        return cp*cy, cp*sy, -sp
    end,

    vector_angles = function(x1, y1, z1, x2, y2, z2)
        --https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/mathlib/mathlib_base.cpp#L535-L563
        local origin_x, origin_y, origin_z
        local target_x, target_y, target_z
        if x2 == nil then
            target_x, target_y, target_z = x1, y1, z1
            origin_x, origin_y, origin_z = client.eye_position()
            if origin_x == nil then
                return
            end
        else
            origin_x, origin_y, origin_z = x1, y1, z1
            target_x, target_y, target_z = x2, y2, z2
        end
    
        --calculate delta of vectors
        local delta_x, delta_y, delta_z = target_x-origin_x, target_y-origin_y, target_z-origin_z
    
        if delta_x == 0 and delta_y == 0 then
            return (delta_z > 0 and 270 or 90), 0
        else
            --calculate yaw
            local yaw = math.deg(math.atan2(delta_y, delta_x))
    
            --calculate pitch
            local hyp = math.sqrt(delta_x*delta_x + delta_y*delta_y)
            local pitch = math.deg(math.atan2(-delta_z, hyp))
    
            return pitch, yaw
        end
    end,

    is_player_moving = function(ent)
        local vec_vel = { entity_get_prop(ent, 'm_vecVelocity') }
        local velocity = math.floor(math.sqrt(vec_vel[1]^2 + vec_vel[2]^2) + 0.5)

        return velocity > 1
    end,

    predict_positions = function(posx, posy, posz, ticks, ent)
        local x, y, z = entity_get_prop(ent, 'm_vecVelocity')
    
        for i = 0, ticks, 1 do
            posx = posx + x * globals.tickinterval()
            posy = posy + y * globals.tickinterval()
            posz = posz + z * globals.tickinterval() + 9.81 * globals.tickinterval() * globals.tickinterval() / 2
        end
    
        return posx, posy, posz
    end
}

functions.calculate_damage = function(local_player, target, predictive)
    local entindex, dmg = -1, -1
    local lx, ly, lz = client.eye_position()

    local px, py, pz = entity.hitbox_position(target, 6) -- middle chest
    local px1, py1, pz1 = entity.hitbox_position(target, 4) -- upper chest
    local px2, py2, pz2 = entity.hitbox_position(target, 2) -- pelvis

    if predictive and functions.is_player_moving(local_player) then
        lx, ly, lz = functions.predict_positions(lx, ly, lz, 20, local_player)
    end
    
    for i=0, 2 do
        if i == 0 then
            entindex, dmg = client.trace_bullet(local_player, lx, ly, lz, px, py, pz)
        else 
            if i==1 then
                entindex, dmg = client.trace_bullet(local_player, lx, ly, lz, px1, py1, pz1)
            else
                entindex, dmg = client.trace_bullet(local_player, lx, ly, lz, px2, py2, pz2)
            end
        end

        if entindex == nil or entindex == local_player or not entity.is_enemy(entindex) then
            return -1
        end
        
        return dmg
    end

    return -1
end

local reset_all = function()
    ui_set(pl_reset, true)

    for i=1, 64, 1 do
        player_data[i] = {
            missed_shots = 0,
            accuracy_boost = 0,
            safe_point = 0,
            body_aim = 0,
        }
    end
end

local prefer_head = ui.new_multiselect('RAGE', 'Other', 'Prefer head-aim', el.prefer_head)
local prefer_body = ui.new_multiselect('RAGE', 'Other', 'Prefer body-aim', el.prefer_body)
local force_body = ui.new_multiselect('RAGE', 'Other', 'Force body-aim', el.prefer_body)
local force_safety = ui.new_multiselect('RAGE', 'Other', 'Force safety', el.prefer_body)
local maximum_misses = ui.new_slider('RAGE', 'Other', 'Force safety after x misses', 0, 10, 0, true, "", 1, { [0] = 'Off' })
local hp_condition = ui.new_slider('RAGE', 'Other', '<x HP Condition', 1, 100, 25)
local baim_predictive = ui.new_checkbox('RAGE', 'Other', 'Predictive body-aim')

local debug_aimpoint = ui.new_checkbox('RAGE', 'Other', 'Debug aim point')
local miss_label = ui.new_label('PLAYERS', 'Adjustments', string.format('Miss count: %s', '0'))

local callback_pl = function(me, e)
    local pl_sp = { [0] = '-', [1] = 'Off', [2] = 'On' }
    local pl_body = { [0] = '-', [1] = 'Off', [2] = 'On', [3] = 'Force' }
    local pl_acb = { [0] = '-', [1] = 'Disable', [2] = 'Low', [3] = 'Medium', [4] = 'High', [5] = 'Maximum' }

    if e == nil or not entity.is_alive(me) then
        return -- INVALID_HANDLE
    end

    local eye_pos = { client.eye_position() }
    local maximum_misses = ui_get(maximum_misses)

    local e_data = player_data[e]
    local e_wpn = entity.get_player_weapon(e)

    local health = entity_get_prop(e, 'm_iHealth')
    local vec_vel = { entity_get_prop(e, 'm_vecVelocity') }
    local velocity = math.floor(math.sqrt(vec_vel[1]^2 + vec_vel[2]^2) + 0.5)

    local avg_shot_time = globals.tickinterval()*14

    local net_data = {
        is_firing = e_wpn ~= nil and (globals.curtime() < (entity_get_prop(e_wpn, 'm_fLastShotTime') + avg_shot_time)),
        is_hp_less = entity_get_prop(e, 'm_iHealth') <= ui_get(hp_condition),
        is_crouching = entity_get_prop(e, 'm_flDuckAmount') >= 0.7,
        is_walking = velocity > 3 and velocity < 100,
        in_air = vec_vel[3]^2 > 0,
    }

    local abs_origin = { entity_get_prop(e, 'm_vecAbsOrigin') }
    local ang_abs = { entity_get_prop(e, 'm_angAbsRotation') }

    local g_damage = functions.calculate_damage(me, e, ui_get(baim_predictive))

    local pitch, yaw = functions.vector_angles(abs_origin[1], abs_origin[2], abs_origin[2], eye_pos[1], eye_pos[2], eye_pos[3])
    local yaw_degress = math.abs(functions.normalize_yaw(yaw - ang_abs[2]))

    net_data.backwards_to_me = yaw_degress > 90 + 45 or yaw_degress < 90 - 45

    e_data.safe_point = 0
    e_data.body_aim = 0
    e_data.accuracy_boost = 0

    local generate_container = function(element)
        return {
            contains(element, 'Force condition'),

            contains(element, 'Target shot fired') and net_data.is_firing,
            contains(element, 'In air') and net_data.in_air,
            contains(element, 'Is crouching') and net_data.is_crouching,
            contains(element, 'Is walking') and net_data.is_walking,
            contains(element, 'Backwards/Forwards') and net_data.backwards_to_me,
            contains(element, 'Sideways') and not net_data.backwards_to_me,

            contains(element, '2 Shots') and g_damage >= (health / 2),
            contains(element, 'Lethal') and g_damage >= health,
            contains(element, '<x HP') and net_data.is_hp_less,
            contains(element, 'Correction active') and ui_get(or_cactive),

            -- contains(element, 'Big desync range') and net_data.big_desync_range,
            -- contains(element, 'Jitter desync') and net_data.desyncing_jitter,
        }
    end

    local prefer_body = generate_container(ui_get(prefer_body))
    local force_body = generate_container(ui_get(force_body))
    local prefer_head = generate_container(ui_get(prefer_head))
    local force_safety = generate_container(ui_get(force_safety))

    local duck_cond = ui_get(fake_duck)

    if contains(prefer_body, true) then e_data.body_aim = 2 end -- Prefer body aim
    if contains(force_body, true) then e_data.body_aim = 3 end -- Force body aim
    if contains(prefer_head, true) then e_data.body_aim = 1 end -- Disable body aim
    if contains(force_safety, true) then e_data.safe_point = 2 end -- Force safe point

    if maximum_misses ~= 0 and e_data.missed_shots >= maximum_misses then
        e_data.safe_point = 2 -- On
    end

    --[[
        if contains(prefer_body, true) or contains(force_body, true) or contains(prefer_head, true) then
            ui_set(or_prefer_baim, false)
            ui_set(or_prefer_baim_disablers, { 
                'Low inaccuracy', 
                'Target shot fired', 
                'Target resolved', 
                'Safe point headshot', 
                'Low damage'
            })
        end
    ]]

    ui_set(or_baim, pl_body[e_data.body_aim])
    ui_set(or_spoint, pl_sp[e_data.safe_point])
    ui_set(or_acb, pl_acb[e_data.accuracy_boost])
end

local aim_miss_pl = function(e)
    local e_data = player_data[e.target]
    e_data.missed_shots = e_data.missed_shots + 1
end

reset_all()

client.set_event_callback('cs_game_disconnected', reset_all)
client.set_event_callback('game_newmap', reset_all)

client.set_event_callback('aim_miss', aim_miss_pl)
client.set_event_callback('paint', function()
    local se_backup = ui.get(shared_esp)
    local ser_backup = ui.get(restrict_shared_esp)

    ui.set(shared_esp, true)
    ui.set(restrict_shared_esp, true)

    client.update_player_list()

    local me = entity.get_local_player()
    local players = entity.get_players(true)
    local pl_cache = ui_get(player_list)

    if not entity.is_alive(me) then
        goto skip_command
    end

    for i=1, #players do
        ui_set(player_list, players[i])

        local handle = ui_get(player_list)

        if handle ~= nil and entity.is_enemy(handle) then
            local e_data = player_data[handle]
            local origin = { entity_get_prop(handle, 'm_vecAbsOrigin') }

            callback_pl(me, handle)

            if origin[1] ~= nil and ui_get(debug_aimpoint) then
                local x1, y1, x2, y2, alpha_multiplier = entity.get_bounding_box(handle)
                if x1 ~= nil and alpha_multiplier > 0 then
                    if y1 - 17 ~= nil then

                        local conds = {
                            baim = ({ [0] = '', [1] = 'HEAD', [2] = 'PREFER', [3] = 'FORCE' })[e_data.body_aim],
                            spoint = ({ [0] = '', [1] = 'UNSAFE', [2] = 'SAFE' })[e_data.safe_point]
                        }

                        local nl = e_data.body_aim ~= 0 and e_data.safe_point ~= 0
                        local retarded_shit = string.format('%s%s%s', nl and ' (' or '', conds.spoint, nl and ')' or '')

                        local alpha = alpha_multiplier*255
                        local alpha = alpha > 255 and 255 or alpha

                        renderer.text(x1 + (x2 - x1)/2, y1-17, 255, 255, 255, alpha, "c-", 0, string.format('%s%s', conds.baim, retarded_shit))
                    end
                end
            end
        end
    end

    ::skip_command::

    if pl_cache ~= nil then
        ui_set(player_list, pl_cache)
        ui_set(miss_label, string.format('Miss count: %s', player_data[pl_cache].missed_shots))
    end

    ui.set(shared_esp, se_backup)
    ui.set(restrict_shared_esp, ser_backup)
end)

client.set_event_callback('shutdown', function()
    client.update_player_list()
    ui_set(pl_reset, true)
end)
