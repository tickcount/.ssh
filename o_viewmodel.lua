local dir, restore = { 'LUA', 'B', 4000, { '-', 'Left hand', 'Right hand' } }
local menu = {
    kpos = ui.new_combobox(dir[1], dir[2], 'Knife positioning', dir[4]),
    fov = ui.new_slider(dir[1], dir[2], 'Viewmodel FOV', -dir[3], dir[3], 0, true, '', 0.01),

    x = ui.new_slider(dir[1], dir[2], 'Viewmodel offset X', -dir[3], dir[3], 0, true, '', 0.01),
    y = ui.new_slider(dir[1], dir[2], 'Viewmodel offset Y', -dir[3], dir[3], 0, true, '', 0.01),
    z = ui.new_slider(dir[1], dir[2], 'Viewmodel offset Z', -dir[3], dir[3], 0, true, '', 0.01),
}

-- cached_vars
local vfov = cvar.viewmodel_fov
local vo_x = cvar.viewmodel_offset_x
local vo_y = cvar.viewmodel_offset_y     
local vo_z = cvar.viewmodel_offset_z
local vo_hand = cvar.cl_righthand

local g_reset = function()
    if restore == nil then
        return
    end

    vfov:set_raw_float(vfov:get_float() - restore.fov)
    vo_x:set_raw_float(vo_x:get_float() - restore.x)
    vo_y:set_raw_float(vo_y:get_float() - restore.y)
    vo_z:set_raw_float(vo_z:get_float() - restore.z)

    vo_hand:set_raw_int(restore.rhand or vo_hand:get_int())

    restore = nil
end

local g_handler = function()
    local rhand = ui.get(menu.kpos)
    local data = {
        fov = ui.get(menu.fov) * 0.0025,
        x = ui.get(menu.x) * 0.0025,
        y = ui.get(menu.y) * 0.0025,
        z = ui.get(menu.z) * 0.0025,
    }

    vfov:set_raw_float(vfov:get_float() + data.fov)
    vo_x:set_raw_float(vo_x:get_float() + data.x)
    vo_y:set_raw_float(vo_y:get_float() + data.y)
    vo_z:set_raw_float(vo_z:get_float() + data.z)

    if rhand ~= dir[4][1] then
        local is_holding_knife = false
        local me = entity.get_local_player()
        local wpn = entity.get_player_weapon(me)
    
        if me ~= nil and wpn ~= nil then
            is_holding_knife = string.match((entity.get_classname(wpn) or ''), 'Knife')
        end
    
        local hand = ({
            [dir[4][1]] = vo_hand:get_int(),
            [dir[4][2]] = is_holding_knife and 0 or 1,
            [dir[4][3]] = is_holding_knife and 1 or 0,
        })[rhand]

        data.rhand = vo_hand:get_int()
        vo_hand:set_raw_int(hand)
    end

    restore = data
end

client.set_event_callback('pre_render', g_handler)
client.set_event_callback('post_render', g_reset)
client.set_event_callback('shutdown', g_reset)
