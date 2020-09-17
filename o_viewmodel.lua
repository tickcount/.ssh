local dir, restore = { 'LUA', 'B', 4000, { '-', 'Left hand', 'Right hand' } }
local menu = {
    kpos = ui.new_combobox(dir[1], dir[2], 'Knife positioning', dir[4]),
    fov = ui.new_slider(dir[1], dir[2], 'Viewmodel FOV', -dir[3], dir[3], 0, true, '', 0.01),

    x = ui.new_slider(dir[1], dir[2], 'Viewmodel offset X', -dir[3], dir[3], 0, true, '', 0.01),
    y = ui.new_slider(dir[1], dir[2], 'Viewmodel offset Y', -dir[3], dir[3], 0, true, '', 0.01),
    z = ui.new_slider(dir[1], dir[2], 'Viewmodel offset Z', -dir[3], dir[3], 0, true, '', 0.01),
}

local get_cvar = client.get_cvar
local vfov = cvar.viewmodel_fov
local vo_x = cvar.viewmodel_offset_x
local vo_y = cvar.viewmodel_offset_y     
local vo_z = cvar.viewmodel_offset_z
local vo_hand = cvar.cl_righthand

local get_original = function()
    return {
        rhand = get_cvar('cl_righthand'),
        fov = get_cvar('viewmodel_fov'),
        
        x = get_cvar('viewmodel_offset_x'),
        y = get_cvar('viewmodel_offset_y'),
        z = get_cvar('viewmodel_offset_z')
    }
end

local g_handler = function(...)
    local shutdown = #({...}) > 0
    local multiplier = shutdown and 0 or 0.0025
    
    local original, data = get_original(), 
    {
        rhand = ui.get(menu.kpos),
        fov = ui.get(menu.fov) * multiplier,
        x = ui.get(menu.x) * multiplier,
        y = ui.get(menu.y) * multiplier,
        z = ui.get(menu.z) * multiplier,
    }

    vfov:set_raw_float(original.fov + data.fov)
    vo_x:set_raw_float(original.x + data.x)
    vo_y:set_raw_float(original.y + data.y)
    vo_z:set_raw_float(original.z + data.z)

    vo_hand:set_raw_int(original.rhand)

    if not shutdown and data.rhand ~= dir[4][1] then
        local is_holding_knife = false
        local me = entity.get_local_player()
        local wpn = entity.get_player_weapon(me)
    
        if me ~= nil and wpn ~= nil then
            is_holding_knife = string.match((entity.get_classname(wpn) or ''), 'Knife')
        end
    
        vo_hand:set_raw_int((
            {
                [dir[4][2]] = is_holding_knife and 0 or 1,
                [dir[4][3]] = is_holding_knife and 1 or 0,
            }
        )[data.rhand])
    end
end

client.set_event_callback('shutdown', function() g_handler(true) end)
client.set_event_callback('pre_render', g_handler)
