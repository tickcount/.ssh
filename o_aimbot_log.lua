local ffi = require("ffi")

ffi.cdef[[
	typedef void***(__thiscall* FindHudElement_t)(void*, const char*);
	typedef void(__cdecl* ChatPrintf_t)(void*, int, int, const char*, ...);
]]

local script = {
	type = { "Console", "Chat" },

	signature_gHud = "\xB9\xCC\xCC\xCC\xCC\x88\x46\x09",
	signature_FindElement = "\x55\x8B\xEC\x53\x8B\x5D\x08\x56\x57\x8B\xF9\x33\xF6\x39\x77\x28",

	-- the last 16 aim_fire events
	g_aim_data = { },
	g_sim_ticks = { },
	g_chokes = { },

	g_tick_base = 0,
	shifted_tick = false,

	hitgroup_names = { "generic", "head", "chest", "stomach", "left arm", "right arm", "left leg", "right leg", "neck", "?", "gear" },

	weapon_to_verb = {
		knife = 'Knifed',
		hegrenade = 'Naded',
		inferno = 'Burned'
	},
}

local log_type = ui.new_multiselect("MISC", "Settings", "Aimbot logging", script.type)

local match = client.find_signature("client_panorama.dll", script.signature_gHud) or error("sig1 not found")
local hud = ffi.cast("void**", ffi.cast("char*", match) + 1)[0] or error("hud is nil")

local helement_match = client.find_signature("client_panorama.dll", script.signature_FindElement) or error("FindHudElement not found")
local hudchat = ffi.cast("FindHudElement_t", helement_match)(hud, "CHudChat") or error("CHudChat not found")

local chudchat_vtbl = hudchat[0] or error("CHudChat instance vtable is nil")
local print_to_chat = ffi.cast("ChatPrintf_t", chudchat_vtbl[27])

local function print_chat(text)
	--[[
		\x01 - white
		\x02 - red
		\x03 - purple
		\x04 - green
		\x05 - yellow green
		\x06 - light green
		\x07 - light red
		\x08 - gray
		\x09 - light yellow
		\x0A - gray
		\x0C - dark blue
		\x10 - gold
	]]

	print_to_chat(hudchat, 0, 0, text)
end

local function reset_aimdata()
	script.g_aim_data = { }
	script.g_sim_ticks = { }
	script.g_chokes = { }
end

local function time_to_ticks(t)
	return math.floor(0.5 + (t / globals.tickinterval()))
end

local function compare(tab, val)
    for i = 1, #tab do
        if tab[i] == val then
            return true
        end
    end
    
    return false
end

client.set_event_callback("net_update_end", function(e)
	local me = entity.get_local_player()
	local players = entity.get_players(true)

	local m_tick_base = entity.get_prop(me, "m_nTickBase")
	
	script.shifted_tick = false

    if m_tick_base < script.g_tick_base then
        script.shifted_tick = true
    end

    script.g_tick_base = m_tick_base

	for i=1, #players do
		local target = players[i]
		local newtick = time_to_ticks(entity.get_prop(target, "m_flSimulationTime"))
		local oldtick = script.g_sim_ticks[target]

		if oldtick ~= nil then
			-- ignore if simulation time went back in time
			-- ignore if the player was dormant for a while (delta is huge)

			local delta = newtick - oldtick

			if delta > 0 and delta <= 64 then
				script.g_chokes[target] = delta
			end
		end

		script.g_sim_ticks[target] = newtick
	end
end)

client.set_event_callback("aim_fire", function(e)
	e.target_choke = script.g_chokes[e.target] or 0
	e.local_choke = globals.chokedcommands()

	script.g_aim_data[e.id % 16] = e
end)

client.set_event_callback("aim_miss", function(e)
	local dtype = ui.get(log_type)
	local on_fire_data = script.g_aim_data[e.id % 16]

	if #dtype == 0 or on_fire_data == nil or on_fire_data.id ~= e.id then
		return
	end

	local flags = {
		e.refined and 'R' or '',
		e.expired and 'X' or '',
		e.noaccept and 'N' or '',
		script.shifted_tick and 'S' or '',
		on_fire_data.teleported and 'T' or '',
		on_fire_data.interpolated and 'I' or '',
		on_fire_data.extrapolated and 'E' or '',
		on_fire_data.boosted and 'B' or '',
		on_fire_data.high_priority and 'H' or ''
	}

	local name = string.lower(entity.get_player_name(e.target))
	local hgroup = script.hitgroup_names[e.hitgroup + 1] or '?'
	local hitchance = math.floor(on_fire_data.hit_chance + 0.5) .. "%%"
	local bt = time_to_ticks(on_fire_data.backtrack)

	if compare(dtype, script.type[1]) then
		print(string.format("[%d] Missed %s's %s(%i)(%s) due to %s, bt=%i (%s) (%i:%i)",
			e.id % 100,
			name,
			hgroup,
			on_fire_data.damage,
			hitchance,
			e.reason,
			bt,
			table.concat(flags),
			on_fire_data.local_choke,
			on_fire_data.target_choke
		))
	end

	if compare(dtype, script.type[2]) then
		print_chat(string.format(" \x08[\x06%d\x08] Missed %s's \x10%s\x08(%i)(%s) due to \x07%s\x08, bt=\x10%i\x08 (\x09%s\x08) (\x10%i\x08:\x10%i\x08)", 
			e.id % 100,
			name,
			hgroup,
			on_fire_data.damage,
			hitchance,
			e.reason,
			bt,
			table.concat(flags),
			on_fire_data.local_choke,
			on_fire_data.target_choke
		))
	end
end)

client.set_event_callback("aim_hit", function(e)
	local dtype = ui.get(log_type)
	local on_fire_data = script.g_aim_data[e.id % 16]

	if #dtype == 0 or on_fire_data == nil or on_fire_data.id ~= e.id then
		return
	end

	local flags = {
		e.refined and 'R' or '',
		script.shifted_tick and 'S' or '',
		on_fire_data.teleported and 'T' or '',
		on_fire_data.interpolated and 'I' or '',
		on_fire_data.extrapolated and 'E' or '',
		on_fire_data.boosted and 'B' or '',
		on_fire_data.high_priority and 'H' or ''
	}

	local name = string.lower(entity.get_player_name(e.target))
	local hgroup = script.hitgroup_names[e.hitgroup + 1] or '?'
	local aimed_hgroup = script.hitgroup_names[on_fire_data.hitgroup + 1] or '?'

	local hitchance = math.floor(on_fire_data.hit_chance + 0.5) .. "%%"
	local bt = time_to_ticks(on_fire_data.backtrack)

	local health = entity.get_prop(e.target, 'm_iHealth')

	if compare(dtype, script.type[1]) then
		print(string.format("[%d] Hit %s's %s for %i(%d) (%i remaining) aimed=%s(%s) bt=%i (%s) (%i:%i)",
			e.id % 100,
			name,
			hgroup,
			e.damage,
			on_fire_data.damage,
			health,
			aimed_hgroup,
			hitchance,
			bt,
			table.concat(flags),
			on_fire_data.local_choke,
			on_fire_data.target_choke
		))
	end

	if compare(dtype, script.type[2]) then
		local prev_dmg = e.damage ~= on_fire_data.damage and " (\x10" .. on_fire_data.damage .. "\x08)" or ""

		print_chat(string.format(" \x08[\x06%d\x08] Hit %s's \x10%s\x08 for \x07%i\x08%s (%i \x08remaining) aimed=\x0C%s\x08(%s) bt=\x10%i\x08 (\x09%s\x08) (\x10%i\x08:\x10%i\x08)",
			e.id % 100,
			name,
			hgroup,
			e.damage,
			prev_dmg,
			health,
			aimed_hgroup,
			hitchance,
			bt,
			table.concat(flags),
			on_fire_data.local_choke,
			on_fire_data.target_choke
		))
	end
end)

client.set_event_callback('player_hurt', function(e)
	local dtype = ui.get(log_type)
    local attacker_id = client.userid_to_entindex(e.attacker)
	
    if #dtype == 0 or attacker_id == nil or attacker_id ~= entity.get_local_player() then
        return
    end

    local group = script.hitgroup_names[e.hitgroup + 1] or "?"
	local target_id = client.userid_to_entindex(e.userid)
	
	if not entity.is_enemy(target_id) then
		return
	end
	
	if group == "generic" then
		if script.weapon_to_verb[e.weapon] ~= nil then
			local target_name = entity.get_player_name(target_id)

			if compare(dtype, script.type[1]) then
				print(string.format("%s %s for %i damage (%i remaining) ", script.weapon_to_verb[e.weapon], string.lower(target_name), e.dmg_health, e.health))
			end

			if compare(dtype, script.type[2]) then
				print_chat(string.format(" \x08%s \x03%s \x08for \x07%i\x08 damage (\x10%i \x08remaining)", script.weapon_to_verb[e.weapon], string.lower(target_name), e.dmg_health, e.health))
			end
		end
	end
end)

client.set_event_callback("cs_game_disconnected", reset_aimdata)
client.set_event_callback("game_newmap", reset_aimdata)
client.set_event_callback("round_end", reset_aimdata)
