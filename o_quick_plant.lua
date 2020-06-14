local entity_get_local_player, entity_get_player_weapon, entity_get_prop, entity_get_classname = entity.get_local_player, entity.get_player_weapon, entity.get_prop, entity.get_classname

local g_command = function(c)
    local me = entity_get_local_player()
    local wpn = entity_get_player_weapon(me)

    local should_fast_plant = 
        entity_get_prop(me, 'm_iTeamNum') == 2 and
        entity_get_classname(wpn) == 'CC4'

    if (c.in_attack == 1 or c.in_use == 1) and should_fast_plant then
        local bomb_zone = entity_get_prop(me, 'm_bInBombZone') == 1

        c.in_use = bomb_zone and 1 or 0
        c.in_attack = bomb_zone and 1 or 0
    end
end

client.set_event_callback('setup_command', g_command)
