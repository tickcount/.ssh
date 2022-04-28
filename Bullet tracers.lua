-- local variables for API functions. any changes to the line below will be lost on re-generation
local bit_band, bit_bor, client_eye_position, client_find_signature, client_userid_to_entindex, entity_get_local_player, entity_get_player_weapon, entity_get_prop, entity_hitbox_position, entity_is_enemy, globals_realtime, globals_tickcount, math_sqrt, table_insert, table_remove, ui_get, ui_new_checkbox, ui_new_color_picker, ui_new_combobox, ui_new_slider, ui_reference, pairs, ui_set, ui_set_callback, ui_set_visible = bit.band, bit.bor, client.eye_position, client.find_signature, client.userid_to_entindex, entity.get_local_player, entity.get_player_weapon, entity.get_prop, entity.hitbox_position, entity.is_enemy, globals.realtime, globals.tickcount, math.sqrt, table.insert, table.remove, ui.get, ui.new_checkbox, ui.new_color_picker, ui.new_combobox, ui.new_slider, ui.reference, pairs, ui.set, ui.set_callback, ui.set_visible

local ffi = require 'ffi'
local sprites = { 
    ['Blue glow'] = "sprites/blueglow1.vmt",
    ['Physbeam'] = "sprites/physbeam.vmt", 
    ['Light glow'] = "sprites/light_glow02.vmt", 
    ['Purple laser'] = "sprites/purplelaser1.vmt", 
}

local bi, bi_duration = ui_reference('VISUALS', 'Effects', 'Bullet impacts')
local master_switch = ui_new_checkbox('VISUALS', 'Effects', 'Bullet beam tracers')
local beam_thickness = ui_new_slider('VISUALS', 'Effects', "\n beam_thickness", 10, 100, 40, true, 'sz', .1)

local beam_sprite = ui_new_combobox('VISUALS', 'Effects', '\n beam_sprite', (function()
    local list = { }

    for name, value in pairs(sprites) do
        list[#list+1] = name
    end

    return list
end)())

ui_set(beam_sprite, 'Purple laser')

local beam_local = ui_new_checkbox('VISUALS', 'Effects', 'Local player tracers')
local beam_local_clr = ui_new_color_picker('VISUALS', 'Effects', '\n beam_local_clr', 37, 96, 142, 145)

local beam_local_hit = ui_new_checkbox('VISUALS', 'Effects', 'Local player tracers hit')
local beam_local_hit_clr = ui_new_color_picker('VISUALS', 'Effects', '\n beam_local_hit_clr', 249, 0, 59, 145)

local beam_enemy = ui_new_checkbox('VISUALS', 'Effects', 'Enemy tracers')
local beam_enemy_clr = ui_new_color_picker('VISUALS', 'Effects', '\n beam_enemy_clr', 155, 54, 187, 255)

ffi.cdef[[
    typedef struct { 
        float x; 
        float y; 
        float z;
    } bbvec3_t;

    struct bbeam_t
    {
        int m_nType;
        void* m_pStartEnt;
        int m_nStartAttachment;
        void* m_pEndEnt;
        int m_nEndAttachment;
        bbvec3_t m_vecStart;
        bbvec3_t m_vecEnd;
        int m_nModelIndex;
        const char* m_pszModelName;
        int m_nHaloIndex;
        const char* m_pszHaloName;
        float m_flHaloScale;
        float m_flLife;
        float m_flWidth;
        float m_flEndWidth;
        float m_flFadeLength;
        float m_flAmplitude;
        float m_flBrightness;
        float m_flSpeed;
        int m_nStartFrame;
        float m_flFrameRate;
        float m_flRed;
        float m_flGreen;
        float m_flBlue;
        bool m_bRenderable;
        int m_nSegments;
        int m_nFlags;
        bbvec3_t m_vecCenter;
        float m_flStartRadius;
        float m_flEndRadius;
    };
]]

local signature = client_find_signature('client.dll', '\xB9\xCC\xCC\xCC\xCC\xA1\xCC\xCC\xCC\xCC\xFF\x10\xA1\xCC\xCC\xCC\xCC\xB9')
local beams = ffi.cast('void**', ffi.cast('char*', signature) + 1)[0]
local beams_ptr = ffi.cast('void***', beams)

local draw_beams = ffi.cast('void (__thiscall*)(void*, void*)', beams_ptr[0][6])
local create_beam_points = ffi.cast('void*(__thiscall*)(void*, struct bbeam_t&)', beams_ptr[0][12])

local create_vec3 = function(vec)
    local ffi_vector = ffi.new('bbvec3_t')

    ffi_vector.x, ffi_vector.y, ffi_vector.z =
        vec[1], vec[2], vec[3]

    return ffi_vector
end

local render_beam = function(_start, _end, clr)
    local beam_info = ffi.new('struct bbeam_t')
    local beam_width = ui_get(beam_thickness) * 0.1

    beam_info.m_vecStart = create_vec3(_start)
    beam_info.m_vecEnd = create_vec3(_end)
    beam_info.m_nSegments = 2
    beam_info.m_nType = 0x00
    beam_info.m_bRenderable = true
    beam_info.m_nFlags = bit_bor(0x00000100 + 0x00000008 + 0x00000200 + 0x00008000)
    beam_info.m_pszModelName = sprites[ui_get(beam_sprite)]
    beam_info.m_nModelIndex = -1
    beam_info.m_flHaloScale = 0.0
    beam_info.m_nStartAttachment = 0
    beam_info.m_nEndAttachment = 0
    beam_info.m_flLife = ui_get(bi_duration)
    beam_info.m_flWidth = beam_width
    beam_info.m_flEndWidth = beam_width
    beam_info.m_flFadeLength = 0.0
    beam_info.m_flAmplitude = 0.0
    beam_info.m_flSpeed = 0.0
    beam_info.m_flFrameRate = 0.0
    beam_info.m_nHaloIndex = 0
    beam_info.m_nStartFrame = 0
    beam_info.m_flBrightness = clr[4]
    beam_info.m_flRed = clr[1]
    beam_info.m_flGreen = clr[2]
    beam_info.m_flBlue = clr[3]

    local beam = create_beam_points(beams_ptr, beam_info)

    if beam ~= nil then 
		draw_beams(beams, beam)
	end
end

local add_to_queue = function(idx, record)
    local me = entity_get_local_player()

    local is_self = me == idx
    local is_enemy = ui_get(beam_enemy) and entity_is_enemy(idx)

    if not is_self and not is_enemy then
        return
    end

    local r, g, b, a = ui_get(
        record.is_enemy and 
        beam_enemy_clr or 
        beam_local_clr
    )

    if not ui_get(beam_local) and is_self and not record.projected then
        return
    end

    if ui_get(beam_local_hit) and not record.is_enemy and record.projected then
        r, g, b, a = ui_get(beam_local_hit_clr)
    end

    render_beam(
        record.origin, 
        record.list[#record.list], 
        { r, g, b, a }
    )
end

-- DO STUFF
local aimbot_fired = false
local old_next_attack = -1
local old_weapon_index = -1
local old_tickcount = -1

local self_angles = { }
local bt_data = { }

local hitgroups = {
    [1] = {0, 1},
    [2] = {4, 5, 6},
    [3] = {2, 3},
    [4] = {13, 15, 16},
    [5] = {14, 17, 18},
    [6] = {7, 9, 11},
    [7] = {8, 10, 12}
}

local add_command = function()
    if ui_get(master_switch) and (ui_get(beam_local) or ui_get(beam_local_hit)) then
        self_angles[#self_angles+1] = {
            m_bPassed = false,
            m_flLife = globals_realtime()+0.5,
            m_vecStart = { client_eye_position() }
        }
    end
end

local callbacks = {
    aim_fire = function(c)
        aimbot_fired = true
        add_command()
    end,

    setup_command = function()
        local me = entity_get_local_player()
        local wpn = entity_get_player_weapon(me)
    
        if me == nil or wpn == nil then
            return
        end

        local next_attack = entity_get_prop(wpn, 'm_flNextPrimaryAttack')
        local weapon_index = bit_band(entity_get_prop(wpn, 'm_iItemDefinitionIndex') or 0, 0xFFFF)
    
        if  aimbot_fired == false and old_next_attack ~= -1 and
            next_attack ~= old_next_attack and weapon_index == old_weapon_index then
            add_command()
        end
    
        aimbot_fired = false
        old_next_attack = next_attack
        old_weapon_index = weapon_index
    end,

    round_start = function()
        bt_data = { }
        self_angles = { }
    end,

    weapon_fire = function(c)
        local tick = globals_tickcount()

        local me = entity_get_local_player()
        local user = client_userid_to_entindex(c.userid)

        if bt_data[user] == nil then bt_data[user] = { } end
        if bt_data[user][tick] == nil then bt_data[user][tick] = { } end

        local new_data = bt_data[user][tick]
        local eye = { entity_hitbox_position(user, 0) }
        local is_enemy = user ~= me and entity_is_enemy(user)

        if user == me then
            local found = false

            for i=1, #self_angles do
                local data = self_angles[i]
                if data ~= nil and not data.m_bPassed then
                    self_angles[i].m_bPassed = true
                    eye, found = data.m_vecStart, true
                    break
                end
            end

            if not found then
                eye = nil
            end
        end

        bt_data[user][tick][#new_data+1] = {
            list = { },
            origin = eye,
            is_enemy = is_enemy,
            dead_time = globals_realtime()+0.5,
            projected = false
        }
    end,

    bullet_impact = function(c)
        local me = entity_get_local_player()
        local user = client_userid_to_entindex(c.userid)

        local tick = globals_tickcount()
        
        if bt_data[user] == nil or bt_data[user][tick] == nil or #bt_data[user][tick] <= 0 then
            return
        end
        
        local records = bt_data[user][tick]

        table_insert(bt_data[user][tick][#records].list, {
            c.x, c.y, c.z
        })
    end,

    player_hurt = function(c)
        local tick = globals_tickcount()
    
        local me = entity_get_local_player()
        local user = client_userid_to_entindex(c.attacker)

        if bt_data[user] == nil or bt_data[user][tick] == nil then
            return
        end

        local closest = math.huge
        local hitboxes = hitgroups[c.hitgroup]
        local record = bt_data[user][tick][#bt_data[user][tick]]
    
        if #record.list <= 0 then
            return
        end

        for i=1, #record.list do
            local current = record.list[i]
    
            if hitboxes ~= nil then
                for j=1, #hitboxes do
                    local x, y, z = entity_hitbox_position(user, hitboxes[j])

                    if x ~= nil then
                        local distance = math_sqrt((current[1] - x)^2 + (current[2] - y)^2 + (current[3] - z)^2)
        
                        if distance < closest then
                            closest = distance
                            record.projected = true
                        end
                    end
                end
            end
        end
    end,

    paint = function()
        local realtime = globals_realtime()
        local me = entity_get_local_player()

        for eid, ent in pairs(bt_data) do
            for _, tick in pairs(ent) do
                if #tick <= 0 or tick == { } then
                    bt_data[eid][_] = nil
                end

                for id, shot in pairs(tick) do
                    local record = bt_data[eid][_][id]

                    if shot.dead_time < realtime or record.origin == nil or #record.list <= 0 then
                        bt_data[eid][_][id] = nil
                    else
                        add_to_queue(eid, record)
                        bt_data[eid][_][id] = nil
                    end
                end

            end
        end

        for i=1, #self_angles do
            if self_angles[i] == nil or self_angles[i].m_bPassed or self_angles[i].m_flLife < realtime then
                table_remove(self_angles, i)
                break
            end
        end
    end
}

local ui_callback = function(c)
    local active, addr = ui_get(c), ''

    if not active then
        addr = 'un'

        aimbot_fired = false
        old_next_attack = -1
        old_weapon_index = -1
        old_tickcount = -1

        self_angles = { }
        bt_data = { }
    end

    local _func = client[addr .. 'set_event_callback']

    ui_set_visible(bi_duration, active or ui_get(bi))
    ui_set_visible(beam_thickness, active)
    ui_set_visible(beam_sprite, active)
    ui_set_visible(beam_local, active)
    ui_set_visible(beam_local_clr, active)
    ui_set_visible(beam_local_hit, active)
    ui_set_visible(beam_local_hit_clr, active)
    ui_set_visible(beam_enemy, active)
    ui_set_visible(beam_enemy_clr, active)

    for name, func in pairs(callbacks) do
        _func(name, func)
    end
end

ui_callback(master_switch)
ui_set_callback(master_switch, ui_callback)
ui_set_callback(bi, ui_callback)
