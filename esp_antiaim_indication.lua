local ffi = require 'ffi'
local ui_get = ui.get

local entity_get_local_player = entity.get_local_player
local entity_get_prop = entity.get_prop
local entity_is_alive = entity.is_alive

local string_format = string.format
local globals_curtime = globals.curtime

local client_camera_angles = client.camera_angles
local client_screen_size = client.screen_size

local bit_band = bit.band
local bit_lshift = bit.lshift

local math_max = math.max
local math_min = math.min
local math_floor = math.floor
local math_abs = math.abs
local math_ceil = math.ceil
local math_sqrt = math.sqrt

local renderer_measure_text = renderer.measure_text
local renderer_rectangle = renderer.rectangle
local renderer_gradient = renderer.gradient
local renderer_text = renderer.text
local renderer_circle_outline = renderer.circle_outline

-- FFI INITIALIZATION
package.plugin_aain = true

local locals = {
    last_choke = 0,
    lby_next_think = 0,
}

local crr_t = ffi.typeof('void*(__thiscall*)(void*)')
local cr_t = ffi.typeof('void*(__thiscall*)(void*)')
local gm_t = ffi.typeof('const void*(__thiscall*)(void*)')
local gsa_t = ffi.typeof('int(__fastcall*)(void*, void*, int)')

ffi.cdef[[
    struct animation_layer_t_12389890123890321890089123 {
        char pad20[24];
        uint32_t m_nSequence;
        float m_flPrevCycle;
        float m_flWeight;
        char pad20[8];
        float m_flCycle;
        void *m_pOwner;
        char pad_0038[ 4 ];
    };

    struct c_animstate_128983475223458080 { 
        char pad[ 3 ];
        char m_bForceWeaponUpdate; //0x4
        char pad1[ 91 ];
        void* m_pBaseEntity; //0x60
        void* m_pActiveWeapon; //0x64
        void* m_pLastActiveWeapon; //0x68
        float m_flLastClientSideAnimationUpdateTime; //0x6C
        int m_iLastClientSideAnimationUpdateFramecount; //0x70
        float m_flAnimUpdateDelta; //0x74
        float m_flEyeYaw; //0x78
        float m_flPitch; //0x7C
        float m_flGoalFeetYaw; //0x80
        float m_flCurrentFeetYaw; //0x84
        float m_flCurrentTorsoYaw; //0x88
        float m_flUnknownVelocityLean; //0x8C
        float m_flLeanAmount; //0x90
        char pad2[ 4 ];
        float m_flFeetCycle; //0x98
        float m_flFeetYawRate; //0x9C
        char pad3[ 4 ];
        float m_fDuckAmount; //0xA4
        float m_fLandingDuckAdditiveSomething; //0xA8
        char pad4[ 4 ];
        float m_vOriginX; //0xB0
        float m_vOriginY; //0xB4
        float m_vOriginZ; //0xB8
        float m_vLastOriginX; //0xBC
        float m_vLastOriginY; //0xC0
        float m_vLastOriginZ; //0xC4
        float m_vVelocityX; //0xC8
        float m_vVelocityY; //0xCC
        char pad5[ 4 ];
        float m_flUnknownFloat1; //0xD4
        char pad6[ 8 ];
        float m_flUnknownFloat2; //0xE0
        float m_flUnknownFloat3; //0xE4
        float m_flUnknown; //0xE8
        float m_flSpeed2D; //0xEC
        float m_flUpVelocity; //0xF0
        float m_flSpeedNormalized; //0xF4
        float m_flFeetSpeedForwardsOrSideWays; //0xF8
        float m_flFeetSpeedUnknownForwardOrSideways; //0xFC
        float m_flTimeSinceStartedMoving; //0x100
        float m_flTimeSinceStoppedMoving; //0x104
        bool m_bOnGround; //0x108
        bool m_bInHitGroundAnimation; //0x109
        float m_flTimeSinceInAir; //0x10A
        float m_flLastOriginZ; //0x10E
        float m_flHeadHeightOrOffsetFromHittingGroundAnimation; //0x112
        float m_flStopToFullRunningFraction; //0x116
        char pad7[ 4 ]; //0x11A
        float m_flMagicFraction; //0x11E
        char pad8[ 60 ]; //0x122
        float m_flWorldForce; //0x15E
        char pad9[ 462 ]; //0x162
        float m_flMaxYaw; //0x334
    };
]]

local classptr = ffi.typeof('void***')
local rawientitylist = client.create_interface('client_panorama.dll', 'VClientEntityList003') or error('VClientEntityList003 wasnt found', 2)

local ientitylist = ffi.cast(classptr, rawientitylist) or error('rawientitylist is nil', 2)
local get_client_networkable = ffi.cast('void*(__thiscall*)(void*, int)', ientitylist[0][0]) or error('get_client_networkable_t is nil', 2)
local get_client_entity = ffi.cast('void*(__thiscall*)(void*, int)', ientitylist[0][3]) or error('get_client_entity is nil', 2)

local rawivmodelinfo = client.create_interface('engine.dll', 'VModelInfoClient004')
local ivmodelinfo = ffi.cast(classptr, rawivmodelinfo) or error('rawivmodelinfo is nil', 2)
local get_studio_model = ffi.cast('void*(__thiscall*)(void*, const void*)', ivmodelinfo[0][32])

local seq_activity_sig = client.find_signature('client_panorama.dll','\x55\x8B\xEC\x53\x8B\x5D\x08\x56\x8B\xF1\x83') or error('error getting seq_activity')

local function get_model(b)if b then b=ffi.cast(classptr,b)local c=ffi.cast(crr_t,b[0][0])local d=c(b)or error('error getting client unknown',2)if d then d=ffi.cast(classptr,d)local e=ffi.cast(cr_t,d[0][5])(d)or error('error getting client renderable',2)if e then e=ffi.cast(classptr,e)return ffi.cast(gm_t,e[0][8])(e)or error('error getting model_t',2)end end end end
local function get_sequence_activity(b,c,d)b=ffi.cast(classptr,b)local e=get_studio_model(ivmodelinfo,get_model(c))if e==nil then return-1 end;local f=ffi.cast(gsa_t, seq_activity_sig)return f(b,e,d)end
local function get_anim_layer(b,c)c=c or 1;b=ffi.cast(classptr,b)return ffi.cast('struct animation_layer_t_12389890123890321890089123**',ffi.cast('char*',b)+0x2980)[0][c]end

local get_color = function(number, max, i)
    local Colors = {
        { 255, 0, 0 }, { 237, 27, 3 }, { 235, 63, 6 }, { 229, 104, 8 },
        { 228, 126, 10 }, { 220, 169, 16 }, { 213, 201, 19 }, { 176, 205, 10 }, { 124, 195, 13 }
    }

    local math_num = function(int, max, declspec)
        local int = (int > max and max or int)
        local tmp = max / int;

        if not declspec then declspec = max end

        local i = (declspec / tmp)
        i = (i >= 0 and math_floor(i + 0.5) or math_ceil(i - 0.5))

        return i
    end

    i = math_num(number, max, #Colors)

    return
        Colors[i <= 1 and 1 or i][1], 
        Colors[i <= 1 and 1 or i][2],
        Colors[i <= 1 and 1 or i][3],
        i
end

local normalize_yaw = function(angle)
    angle = (angle % 360 + 360) % 360
    return angle > 180 and angle - 360 or angle
end

-- Cheat references
local aa_enabled = ui.new_multiselect('AA', 'Other', 'Anti-aim indication', 'Panel', 'Arrows')
local arrows_color = ui.new_color_picker('AA', 'Other', 'Anti-aim arrows color', 89, 119, 239, 255)
local arrows_offset = ui.new_slider('AA', 'Other', 'Anti-aim arrows offset', 10, 200, 50)

local g_lby_controller = function(c)
    local curtime = globals_curtime()
    local me = entity_get_local_player()

    local lpent = get_client_entity(ientitylist, me)
    local lpentnetworkable = get_client_networkable(ientitylist, me)

    local user_ptr = ffi.cast(classptr, lpent)
    local animstate_ptr = ffi.cast("char*", user_ptr) + 0x3914
    local me_animstate = ffi.cast("struct c_animstate_128983475223458080**", animstate_ptr)[0]

    local is_on_ground = function(player)
        local m_fFlags = entity_get_prop(player, 'm_fFlags')
        local on_ground = bit_band(m_fFlags, bit_lshift(1, 0)) == 1

        return on_ground
    end

    locals.last_choke = c.chokedcommands

    if lpent == nil or lpentnetworkable == nil or me_animstate == nil then 
        return
    end

    -- print(' ')

    for i=1, 12 do
        local layer = get_anim_layer(lpent, i)

        if layer.m_pOwner ~= nil then
            local act = get_sequence_activity(lpent, lpentnetworkable, layer.m_nSequence)

            if act ~= -1 then
                -- print(string_format('act: %.5f weight: %.5f cycle: %.5f', act, layer.m_flWeight, layer.m_flCycle))
            end

            if c.chokedcommands == 0 then
                locals.lby_can_update = is_on_ground(me) and me_animstate.m_flSpeed2D <= 1.0
            end

            if not locals.lby_can_update then
                locals.lby_next_think = curtime + 0.22
            elseif act == 979 then
                if layer.m_flWeight >= 0.0 and layer.m_flCycle <= 0.070000 then
                    if locals.lby_next_think < curtime then
                        locals.lby_next_think = curtime + 1.1
                    end
                elseif layer.m_flWeight == 0 and layer.m_flCycle <= 0.070000 then
                    locals.lby_can_update = false
                end
            end
        end
    end
end

--region retarded gay nigga shit
local notes_pos = function(b)
    local c=function(d,e)
        local f={}
        for g in pairs(d) do 
            table.insert(f,g)
        end;
        table.sort(f,e)
        local h=0;
        local i=function()
            h=h+1;
            if f[h]==nil then 
                return nil 
            else 
                return f[h],d[f[h]]
            end 
        end;
        return i 
    end;
    
    local j={
        get=function(k)
            local l,m=0,{}
            for n,o in c(package.cnotes) do 
                if o==true then 
                    l=l+1;m[#m+1]={n,l}
                end 
            end;
            for p=1,#m do 
                if m[p][1]==b then 
                    return k(m[p][2]-1)
                end 
            end 
        end,
        
        set_state=function(q)
            package.cnotes[b]=q;
            table.sort(package.cnotes)
        end,
        unset=function()
            client.unset_event_callback('shutdown',callback)
        end
    }
    
    client.set_event_callback('shutdown',function()
        if package.cnotes[b]~=nil then package.cnotes[b]=nil end
    end)
    
    if package.cnotes==nil then 
        package.cnotes={}
    end;

    return j 
end
--endregion

local note = notes_pos 'b_aa_indicators.v1'
local g_paint_handler = function()
    note.set_state(false)

    local me = entity_get_local_player()

    local _, camera_yaw = client_camera_angles()
    local _, rotation = entity_get_prop(me, 'm_angAbsRotation')
    local body_pos = entity_get_prop(me, "m_flPoseParameter", 11) or 0
    
    local body_yaw = math_max(-60, math_min(60, body_pos*120-60+0.5))
    body_yaw = (body_yaw < 1 and body_yaw > 0.0001) and math_floor(body_yaw, 1) or body_yaw

    if camera_yaw ~= nil and rotation ~= nil and 60 < math_abs(normalize_yaw(camera_yaw-(rotation+body_yaw))) then
        body_yaw = -body_yaw
    end

    local enabled, arrows_color = ui_get(aa_enabled), { ui_get(arrows_color) }
    local success, _, data2 = pcall(ui.reference, 'CONFIG', 'Presets', 'Watermark')

    local is_active = #enabled > 0 and ui_get(aa_enabled) and entity_is_alive(me)

    if not is_active then
        locals = {
            last_choke = 0,
            lby_next_think = 0,
        }
    end

    local abs_yaw = math_abs(body_yaw)
    local r, g, b, a = get_color(abs_yaw, 30)
    local side = body_yaw < 0 and '>' or (body_yaw > 0.999 and '<' or '-')

    if not is_active then
        return
    end

    for i=1, #enabled do
        if enabled[i] == 'Panel' then
            note.set_state(true)
            note.get(function(id)
                local timer = (locals.lby_next_think - globals_curtime()) / 1.1 * 1
                local add_text = (locals.lby_can_update and timer >= 0) and '     ' or ''
    
                local text = string_format('%sFAKE (%.1f°) | safety: %.0f%% | side: %s', add_text, abs_yaw, abs_yaw/60*100, side)
                local h, w = 17, renderer_measure_text(nil, text) + 8
                local x, y = client_screen_size(), 10 + (25*id)
                
                local alpha = (success and ({ ui_get(data2) })[4] or 255)
        
                x = x - w - 10
        
                renderer_rectangle(x-3, y, 2, h, r, g, b, 255)
                renderer_gradient(x-1, y, (w+1) / 2, h, 0, 0, 0, 25, 17, 17, 17, alpha, true)
                renderer_gradient(x-1 + w/2, y, (w+1) / 2, h, 17, 17, 17, alpha, 0, 0, 0, 25, true)
                renderer_text(x+4, y + 2, 255, 255, 255, 255, "", 0, text)
    
                if locals.lby_can_update and timer >= 0 then
                    renderer_circle_outline(x+9, y + 8.5, 89, 119, 239, 255, 5, 0, timer, 2)
                end
            end)
        end

        if enabled[i] == 'Arrows' then
            local m_vecvel = { entity_get_prop(me, 'm_vecVelocity') }
            local velocity = math_floor(math_sqrt(m_vecvel[1]^2 + m_vecvel[2]^2 + m_vecvel[3]^2) + 0.5)

            local screen_size = { client_screen_size() }
            local half_ss = { screen_size[1]/2, screen_size[2]/2 }

            local clr = {
                ['<'] = { 255, 255, 255, arrows_color[4] / (velocity > 35 and 2 or 1) },
                ['>'] = { 255, 255, 255, arrows_color[4] / (velocity > 35 and 2 or 1) },
                ['-'] = { 0, 0, 0, 255 }
            }

            clr[side] = { arrows_color[1], arrows_color[2], arrows_color[3], clr[side][4] }

            renderer_text(half_ss[1] - ui_get(arrows_offset), half_ss[2], clr['<'][1], clr['<'][2], clr['<'][3], clr['<'][4], 'c+', 0, '<')
            renderer_text(half_ss[1] + ui_get(arrows_offset), half_ss[2], clr['>'][1], clr['>'][2], clr['>'][3], clr['>'][4], 'c+', 0, '>')
        end
    end
end

client.set_event_callback('setup_command', g_lby_controller)
client.set_event_callback('paint', g_paint_handler)
