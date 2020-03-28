local active = ui.new_checkbox('CONFIG', 'Presets', 'Watermark')
local color_picker = ui.new_color_picker('CONFIG', 'Presets', 'Watermark color picker', 89, 119, 239, 255)

-- Things
local ffi = require 'ffi'

local nickname = 'Salvatore'
local ctag = 'skeet.cc [metamod]'

ffi.cdef('typedef bool(__thiscall* is_ingame_t)(void*);')
ffi.cdef('typedef void*(__thiscall* get_net_channel_info_t)(void*);')
ffi.cdef('typedef float(__thiscall* get_avg_latency_t)(void*, int);')

local interface_ptr = ffi.typeof('void***')
local rawivengineclient = client.create_interface('engine.dll', 'VEngineClient014') or error('VEngineClient014 wasnt found', 2)
local ivengineclient = ffi.cast(interface_ptr, rawivengineclient) or error('rawivengineclient is nil', 2)

local get_net_channel_info = ffi.cast('get_net_channel_info_t', ivengineclient[0][78]) or error('ivengineclient is nil')
local is_in_game = ffi.cast('is_ingame_t', ivengineclient[0][26]) or error('is_in_game is nil')

local notes_pos = function(b)local c=function(d,e)local f={}for g in pairs(d)do table.insert(f,g)end;table.sort(f,e)local h=0;local i=function()h=h+1;if f[h]==nil then return nil else return f[h],d[f[h]]end end;return i end;local j={get=function(k)local l,m=0,{}for n,o in c(package.cnotes)do if o==true then l=l+1;m[#m+1]={n,l}end end;for p=1,#m do if m[p][1]==b then return k(m[p][2]-1)end end end,set_state=function(q)package.cnotes[b]=q;table.sort(package.cnotes)end,unset=function()client.unset_event_callback('shutdown',callback)end}client.set_event_callback('shutdown',function()if package.cnotes[b]~=nil then package.cnotes[b]=nil end end)if package.cnotes==nil then package.cnotes={}end;return j end
local syn = notes_pos 'a_watermark'

local paint_handler = function()
    syn.set_state(ui.get(active))
    syn.get(function(id)
        local sys_time = { client.system_time() }
        local actual_time = string.format('%02d:%02d:%02d', sys_time[1], sys_time[2], sys_time[3])

        local text = string.format('%s | %s | %s', ctag, nickname, actual_time)

        if is_in_game(is_in_game) == true then
            local INetChannelInfo = ffi.cast('void***', get_net_channel_info(ivengineclient)) or error('netchaninfo is nil')
            local get_avg_latency = ffi.cast('get_avg_latency_t', INetChannelInfo[0][10])
            local latency = get_avg_latency(INetChannelInfo, 0) * 1000
            local tick = 1/globals.tickinterval()

            text = string.format('%s | %s | delay: %dms | %dtick | %s', ctag, nickname, latency, tick, actual_time)
        end

        local r, g, b, a = ui.get(color_picker)
        local h, w = 18, renderer.measure_text(nil, text) + 8
        local x, y = client.screen_size(), 10 + (25*id)

        x = x - w - 10

        renderer.rectangle(x, y, w, 2, r, g, b, 255)
        renderer.rectangle(x, y + 2, w, h, 17, 17, 17, a)
        renderer.text(x+4, y + 4, 255, 255, 255, 255, '', 0, text)
    end)
end

client.set_event_callback('paint_ui', paint_handler)
