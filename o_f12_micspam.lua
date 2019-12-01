local sound_exists = function(name)
    return (function(filename) return package.searchpath("", filename) == filename end)("./" .. name)
end

local disable_func = function()
    cvar.voice_loopback:set_int(0)
    cvar.voice_inputfromfile:set_int(0)
    client.exec('-voicerecord')
end

local handler = nil
local timer, enabled = 0, true

handler = function()
    if globals.realtime() >= timer then
        timer = globals.realtime() + 0.6
        
        if enabled then
            disable_func()
            enabled = false
        end
    end

    client.delay_call(0.001, handler)
end

local active = ui.new_checkbox("MISC", "Miscellaneous", "F12 sound (microphone)")
local loopback = ui.new_checkbox("MISC", "Miscellaneous", "Sound loop back")

client.set_event_callback("shutdown", disable_func)
client.set_event_callback("player_death", function(e)
    local victim_userid, attacker_userid = e.userid, e.attacker

    if not ui.get(active) or victim_userid == nil or attacker_userid == nil then
        return
    end

    if not sound_exists('voice_input.wav') then
        ui.set(active, false)
        error("no sound ./voice_input.wav")
    end
	
    local attacker_entindex = client.userid_to_entindex(attacker_userid)
    local victim_entindex = client.userid_to_entindex(victim_userid)
    
    if attacker_entindex == entity.get_local_player() then
        local lb_active = ui.get(loopback) and 1 or 0

        cvar.voice_loopback:set_int(lb_active)
        cvar.voice_inputfromfile:set_int(1)

        client.exec('+voicerecord')
        timer, enabled = globals.realtime() + 0.6, true
    end
end)

local callback = function()
    ui.set_visible(loopback, ui.get(active))
end

ui.set_callback(active, callback)
callback()
handler()
