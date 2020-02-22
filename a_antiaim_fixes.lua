local ref_pitch = ui.reference('AA', 'Anti-aimbot angles', 'Pitch')
local disable_twist = ui.new_checkbox('AA', 'Anti-aimbot angles', 'Disable twist')

local command_setup = function(e)
    local me = entity.get_local_player()
    local wpn = entity.get_player_weapon(me)

    local vel = { entity.get_prop(me, 'm_vecVelocity') }
    local in_move = math.sqrt(vel[1]^2 * vel[2]^2) > 1 and not (vel[3]^2 > 0)

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

    if ui.get(disable_twist) and in_move then
        ui.set(ref_pitch, 'Off')
    end
end

client.set_event_callback('setup_command', command_setup)
client.set_event_callback('run_command', function()
    if ui.get(disable_twist) then
        ui.set(ref_pitch, 'Down')
    end
end)
