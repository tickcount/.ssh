local ffi = require 'ffi'

local ref_pitch = ui.reference('AA', 'Anti-aimbot angles', 'Pitch')
local ref_bodyyaw = ui.reference('AA', 'Anti-aimbot angles', 'Body yaw')

local duck_peek_assist = ui.reference('RAGE', 'Other', 'Duck peek assist')
local disable_twist = ui.new_checkbox('AA', 'Anti-aimbot angles', 'Disable twist')

local global_pitch = nil

ffi.cdef[[
    typedef void*(__thiscall* get_client_entity_t)(void*, int); // 3
    typedef void*(__thiscall* get_client_networkable_t)(void*, int); // 0
    typedef void*(__thiscall* get_client_unknown_t)(void*); // 0
    typedef void*(__thiscall* get_client_renderable_t)(void*); // 2
    typedef const void*(__thiscall* get_model_t)(void*); // 8
    typedef void*(__thiscall* get_studio_model_t)(void*, const void*); // 32
    typedef int(__fastcall* get_sequence_activity_t)(void*, void*, int);

    struct animation_layer_t {
        char pad20[24];
        uint32_t m_nSequence;
        float m_flPrevCycle;
        float m_flWeight;
        char pad20[8];
        float m_flCycle;
        void *m_pOwner;
        char pad_0038[ 4 ];
    };
]]

local classptr = ffi.typeof('void***')
local rawientitylist = client.create_interface('client_panorama.dll', 'VClientEntityList003') or error('VClientEntityList003 wasnt found', 2)

local ientitylist = ffi.cast(classptr, rawientitylist) or error('rawientitylist is nil', 2)
local get_client_networkable = ffi.cast('get_client_networkable_t', ientitylist[0][0]) or error('get_client_networkable_t is nil', 2)
local get_client_entity = ffi.cast('get_client_entity_t', ientitylist[0][3]) or error('get_client_entity is nil', 2)

local rawivmodelinfo = client.create_interface('engine.dll', 'VModelInfoClient004')
local ivmodelinfo = ffi.cast(classptr, rawivmodelinfo) or error('rawivmodelinfo is nil', 2)
local get_studio_model = ffi.cast('get_studio_model_t', ivmodelinfo[0][32])

local seq_activity_sig = client.find_signature('client_panorama.dll','\x55\x8B\xEC\x53\x8B\x5D\x08\x56\x8B\xF1\x83') or error('error getting seq_activity')

local function get_model(b)if b then b=ffi.cast(classptr,b)local c=ffi.cast('get_client_unknown_t',b[0][0])local d=c(b)or error('error getting client unknown',2)if d then d=ffi.cast(classptr,d)local e=ffi.cast('get_client_renderable_t',d[0][5])(d)or error('error getting client renderable',2)if e then e=ffi.cast(classptr,e)return ffi.cast('get_model_t',e[0][8])(e)or error('error getting model_t',2)end end end end
local function get_sequence_activity(b,c,d)b=ffi.cast(classptr,b)local e=get_studio_model(ivmodelinfo,get_model(c))if e==nil then return-1 end;local f=ffi.cast('get_sequence_activity_t', seq_activity_sig)return f(b,e,d)end
local function get_anim_layer(b,c)c=c or 1;b=ffi.cast(classptr,b)return ffi.cast('struct animation_layer_t**',ffi.cast('char*',b)+0x2980)[0][c]end

client.set_event_callback('predict_command', function()
    local me = entity.get_local_player()

    local lpent = get_client_entity(ientitylist, me)
    local lpentnetworkable = get_client_networkable(ientitylist, me)

    if not (lpent and lpentnetworkable and ui.get(ref_bodyyaw) ~= 'Off') then 
        return
    end

    for i=1, 12 do
        local layer = get_anim_layer(lpent, i)

        if layer.m_pOwner ~= nil then
            local sequence_activity = get_sequence_activity(lpent, lpentnetworkable, layer.m_nSequence)

            if sequence_activity == 979 then
                layer.m_flCycle = 0
                layer.m_flWeight = 0
            end
        end
    end
end)

client.set_event_callback('setup_command', function(e)
    local me = entity.get_local_player()
    local wpn = entity.get_player_weapon(me)

    local vel = { entity.get_prop(me, 'm_vecVelocity') }

    if wpn ~= nil and entity.get_classname(wpn) == 'CC4' then
        if e.in_attack == 1 then
            e.in_attack = 0
            e.in_use = 1
        end
    else
        if e.chokedcommands == 2 then
            e.in_use = 0 
        end
    end

    if ui.get(disable_twist) and not ui.get(duck_peek_assist) and not (vel[3]^2 > 0) then
        global_pitch = global_pitch or ui.get(ref_pitch)

        if global_pitch ~= nil then
            ui.set(ref_pitch, 'Off')
        end
    end
end)

client.set_event_callback('run_command', function()
    if ui.get(disable_twist) and global_pitch ~= nil then
        ui.set(ref_pitch, global_pitch)
        global_pitch = nil
    end
end)
