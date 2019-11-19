local math_atan2 = math.atan2
local math_sqrt = math.sqrt
local math_abs = math.abs
local math_floor = math.floor
local math_cos = math.cos
local math_sin = math.sin

local entity_get_players = entity.get_players
local client_trace_line = client.trace_line
local client_eye_position = client.eye_position
local client_camera_angles = client.camera_angles

local entity_is_alive = entity.is_alive
local entity_hitbox_position = entity.hitbox_position
local renderer_world_to_screen = renderer.world_to_screen
local renderer_measure_text = renderer.measure_text
local renderer_indicator = renderer.indicator
local renderer_rectangle = renderer.rectangle
local renderer_text = renderer.text

local ui_get, ui_set = ui.get, ui.set
local get_local = entity.get_local_player
local get_prop = entity.get_prop

local ffi = require "ffi"

ffi.cdef[[
    typedef void*(__thiscall* lm_get_client_entity_t)(void*, int);
    typedef bool(__thiscall* through_smoke)(float, float, float, float, float, float, short);
	
    struct lm_animstate_s
	{
		void *pThis;
		char pad2[91];
		void* m_unknown; //0x60
		void* m_unknown; //0x64
		void* m_unknown; //0x68
		float m_unknown; //0x6C
		int m_unknown; //0x70
		float m_unknown; //0x74
		float m_unknown; //0x78
		float m_unknown; //0x7C
		float feet_yaw; //0x80
	};
]]

-- Line goes through smoke
-- Credits: rave1338

local lgts_sig = "\x55\x8B\xEC\x83\xEC\x08\x8B\x15\xCC\xCC\xCC\xCC\x0F\x57"
local lgts_signature = client.find_signature("client_panorama.dll", lgts_sig)
local raw_ent_list = client.create_interface("client_panorama.dll", "VClientEntityList003")
local ent_list = ffi.cast(ffi.typeof("void***"), raw_ent_list)

local get_client_entity = ffi.cast("lm_get_client_entity_t", ent_list[0][3])
local lgts_function = ffi.cast("through_smoke", lgts_signature)

local function vector(_x, _y, _z) return { x = _x or 0, y = _y or 0, z = _z or 0 } end
local function rad2deg(rad) return (rad * 180 / math.pi) end

local function clamp_angles(angle)
    angle = angle % 360 
    angle = (angle + 360) % 360

    if angle > 180 then
        angle = angle - 360
    end

    return angle
end

local contains = function(tab, val, sys)
    for index, value in ipairs(tab) do
        if sys == 1 and index == val then 
            return true
        elseif value == val then
            return true
        end
    end
 
    return false
end

local find_cmd = function(tab, value)
    for k, v in pairs(tab) do
        if contains(v, value) then
            return k
        end
    end

    return nil
end

local ui_mset = function(list)
    for ref, val in pairs(list) do
        ui_set(ref, val)
    end
end

local var_direction = {
    "Safe",
    "Maximum"
}

local edge_count = { [1] = 7, [2] = 12, [3] = 15, [4] = 19, [5] = 23, [6] = 28, [7] = 29 }
local names = { "Head", "Chest", "Stomach" --[[, "Arms", "Legs", "Feet" ]] }

local hitscan = {
    ["Head"] = { 0, 1 },
    ["Chest"] = { 2, 3, 4 },
    ["Stomach"] = { 5, 6 },
    ["Arms"] = { 13, 14, 15, 16, 17, 18 },
    ["Legs"] = { 7, 8, 9, 10 },
    ["Feet"] = { 11, 12 }
}

local legit_active, legit_key = ui.reference("Legit", "Aimbot", "Enabled")
local rage_active, active_key = ui.reference("RAGE", "Aimbot", "Enabled")
local rage_selection = ui.reference("RAGE", "Aimbot", "Target selection")
local rage_hitbox = ui.reference("RAGE", "Aimbot", "Target hitbox")
local rage_recoil = ui.reference("RAGE", "Other", "Remove recoil")
local rage_autowall = ui.reference("RAGE", "Aimbot", "Automatic penetration")
local rage_fakeduck = ui.reference("RAGE", "Other", "Duck peek assist")
local infinite_duck = ui.reference("MiSC", "Movement", "Infinite duck")
local auto_pistols = ui.reference("MISC", "Miscellaneous", "Automatic weapons")

local autofire = ui.reference("RAGE", "Aimbot", "Automatic fire")
local psilent = ui.reference("RAGE", "Aimbot", "Silent aim")
local aimstep = ui.reference("RAGE", "Aimbot", "Reduce aim step")
local maximum_fov = ui.reference("RAGE", "Aimbot", "Maximum FOV")

local flag_limit = ui.reference("AA", "Fake lag", "Limit")
local pitch = ui.reference("AA", "Anti-aimbot angles", "Pitch")
local yaw_base = ui.reference("AA", "Anti-aimbot angles", "Yaw base")
local yaw, yaw_num = ui.reference("AA", "Anti-aimbot angles", "Yaw")
local yaw_jitter = ui.reference("AA", "Anti-aimbot angles", "Yaw jitter")
local body, body_num = ui.reference("AA", "Anti-aimbot angles", "Body yaw")
local limit = ui.reference("AA", "Anti-aimbot angles", "Fake yaw limit")
local lby = ui.reference("AA", "Anti-aimbot angles", "Lower body yaw target")

local playerlist = ui.reference("PLAYERS", "Players", "Player list")
local whitelist = ui.reference("PLAYERS", "Adjustments", "Add to whitelist")
local reset_all = ui.reference("PLAYERS", "Players", "Reset all")

local menu = {
    enabled = ui.new_checkbox("RAGE", "Other", "Rage aimbot assistance"),

    ov_autowall = ui.new_checkbox("RAGE", "Other", "Override automatic penetration"),
    ov_autowall_key = ui.new_hotkey("RAGE", "Other", "Override penetration key", true),

    smoke_check = ui.new_checkbox("RAGE", "Other", "Aim throught smoke"),
    nearest = ui.new_multiselect("RAGE", "Other", "Nearest hitboxes", names),

    legit_aa = ui.new_checkbox("RAGE", "Other", "Legit anti-aim"),
    direction = ui.new_combobox("RAGE", "Other", "\n legitmode_aa_direction", var_direction),

    edge_factor = ui.new_slider("RAGE", "Other", "Edge count per side \n legitmode_edges_factor", 1, 7, 3),
    edge_distance = ui.new_slider("RAGE", "Other", "\n legitmode_edges_distance", 0, 50, 25, true, "in"),

    draw_edges = ui.new_checkbox("RAGE", "Other", "Draw anti-aim edges"),
    edge_picker = ui.new_color_picker("RAGE", "Other", "\n legitmode_edges_clr", 32, 160, 230, 255),
}

local function set_visible()
    local active = ui_get(menu.enabled)
    local legit_aa = ui_get(menu.legit_aa)

    ui.set_visible(menu.ov_autowall, active)
    ui.set_visible(menu.ov_autowall_key, active)

    ui.set_visible(menu.smoke_check, active)
    ui.set_visible(menu.nearest, active)

    ui.set_visible(menu.legit_aa, active)
    ui.set_visible(menu.direction, active and legit_aa)

    ui.set_visible(menu.edge_factor, active and legit_aa)
    ui.set_visible(menu.edge_distance, active and legit_aa)

    ui.set_visible(menu.draw_edges, active and legit_aa)
    ui.set_visible(menu.edge_picker, active and legit_aa)
end

local function get_atan(ent, eye_pos, camera)
    local data = { id = nil, dst = 2147483647 }

    local vector_substract = function(vector1, vector2)
        return { 
            x = vector1.x - vector2.x, 
            y = vector1.y - vector2.y, 
            z = vector1.z - vector2.z
        }
    end

    for i = 0, 19 do
        local hitbox = vector(entity_hitbox_position(ent, i))
        local ext = vector_substract(hitbox, eye_pos)

        local yaw = rad2deg(math_atan2(ext.y, ext.x))
        local pitch = -rad2deg(math_atan2(ext.z, math_sqrt(ext.x^2 + ext.y^2)))
    
        local yaw_dif = math_abs(camera.y % 360 - yaw % 360) % 360
        local pitch_dif = math_abs(camera.x - pitch) % 360
            
        if yaw_dif > 180 then 
            yaw_dif = 360 - yaw_dif
        end

        local dst = math_sqrt(yaw_dif^2 + pitch_dif^2)

        if dst < data.dst then
            data.dst = dst
            data.id = i
        end
    end

    return data.id, data.dst
end

local function get_nearbox(z_pos)
    client.update_player_list()

    local plist_bk = ui_get(playerlist)
    local get_players = entity_get_players(true)
    local closest = { enemy = nil, hitbox = nil, dst = 2147483647 }
    
    if #get_players == 0 then
        return
    end

    local smoke_check = not ui_get(menu.smoke_check)
    local eye_pos = vector(client_eye_position())
    local camera = vector(client_camera_angles())

    camera.z = z_pos ~= nil and 64 or camera.z

    local local_head = { entity_hitbox_position(get_local(), 0) }

    for i = 1, #get_players do
        local can_select = true
        local hitbox_id, distance = 
            get_atan(get_players[i], eye_pos, camera)

        if distance < closest.dst then
            if smoke_check then
                local hitbox = { entity_hitbox_position(get_players[i], hitbox_id) }

                if hitbox[1] ~= nil then
                    can_select = not lgts_function(local_head[1], local_head[2], local_head[3], hitbox[1], hitbox[2], hitbox[3], 1)
                end
            end

            ui_set(playerlist, get_players[i])
            ui_set(whitelist, not can_select)

            if can_select then
                closest = {
                    dst = distance,
                    hitbox = hitbox_id,
                    enemy = get_players[i]
                }
            end
        end
    end

    if plist_bk ~= nil then
        ui_set(playerlist, plist_bk)
    end

    return closest.enemy, closest.hitbox, closest.dst
end

local function do_legit_aa(local_player)
    if not entity_is_alive(local_player) then
        return
    end

    local vector_add = function(vector1, vector2)
        return { 
            x = vector1.x + vector2.x, 
            y = vector1.y + vector2.y, 
            z = vector1.z + vector2.z
        }
    end

    local trace_line = function(entity, start, _end)
        return client_trace_line(entity, start.x, start.y, start.z, _end.x, _end.y, _end.z)
    end

    local m_vecOrigin = vector(get_prop(local_player, "m_vecOrigin"))
    local m_vecViewOffset = vector(get_prop(local_player, "m_vecViewOffset"))

    local m_vecOrigin = vector_add(m_vecOrigin, m_vecViewOffset)

    local radius = 20 + ui_get(menu.edge_distance) + 0.1
    local step = math.pi * 2.0 / edge_count[ui_get(menu.edge_factor)]

    local camera = vector(client_camera_angles())
    local central = math_floor(camera.y + 0.5) * math.pi / 180

    local data = {
        fraction = 1,
        surpassed = false,
        angle = vector(0, 0, 0),
        var = 0,
        side = "LAST KNOWN"
    }

    for a = central, math.pi * 3.0, step do
        if a == central then
            central = clamp_angles(rad2deg(a))
        end

        local clm = clamp_angles(central - rad2deg(a))
        local abs = math_abs(clm)

        if abs < 90 and abs > 1 then
            local side = "LAST KNOWN"
            local location = vector(
                radius * math_cos(a) + m_vecOrigin.x, 
                radius * math_sin(a) + m_vecOrigin.y, 
                m_vecOrigin.z
            )

            local _fr, entindex = trace_line(local_player, m_vecOrigin, location)

            if math_floor(clm + 0.5) < -21 then side = "LEFT" end
            if math_floor(clm + 0.5) > 21 then side = "RIGHT" end

            local fr_info = {
                fraction = _fr,
                surpassed = (_fr < 1),
                angle = vector(0, clamp_angles(rad2deg(a)), 0),
                var = math_floor(clm + 0.5),
                side = side --[ 0 - center / 1 - left / 2 - right ]
            }

            if data.fraction > _fr then data = fr_info end

            if ui_get(menu.draw_edges) then
                local world_to_screen = function(x, y, z, func)
                    local x, y = renderer_world_to_screen(x, y, z)
                    if x ~= nil and y ~= nil then 
                        func(x, y)
                    end
                end

                world_to_screen(location.x, location.y, location.z - m_vecViewOffset.z, function(x, y)
                    local r, g, b = 255, 255, 255
                    if fr_info.surpassed then
                        r, g, b = ui_get(menu.edge_picker)
                    end

                    renderer_text(x, y, r, g, b, 255, "c", 0, "•")
                end)
            end
        end
    end

    return data
end

set_visible()

ui.set_callback(menu.enabled, set_visible)
ui.set_callback(menu.legit_aa, set_visible)

local cache = { }
local cache_process = function(name, condition, should_call, a, b)
    cache[name] = cache[name] ~= nil and cache[name] or ui_get(condition)

    if should_call then
        if type(a) == "function" then a() else
            ui_set(condition, a)
        end
    else
        if cache[name] ~= nil then
            if b ~= nil and type(b) == "function" then
                b(cache[name])
            else
                ui_set(condition, cache[name])
            end

            cache[name] = nil
        end
    end
end

client.set_event_callback("setup_command", function(cmd)
    local local_player = get_local()
    
    if not ui_get(menu.enabled) then
        return
    end

    if ui_get(menu.ov_autowall) then
        ui_set(rage_autowall, ui_get(menu.ov_autowall_key))
    end

    local fov = ui_get(maximum_fov)
    local ractive = ui_get(rage_active)

    local in_legit = ui_get(legit_active) and ui_get(legit_key)
    local fakeduck_ready = ractive and ui_get(infinite_duck) and ui_get(rage_fakeduck)

    local enemy, hid, dst = get_nearbox(fakeduck_ready)
    local hitbox = find_cmd(hitscan, hid)

    ui_mset({
        [rage_selection] = 'Near crosshair',
        [rage_hitbox] = contains(ui_get(menu.nearest), hitbox) and hitbox or ui_get(rage_hitbox),

        [maximum_fov] = fov > 10 and 10 or fov,
        [rage_recoil] = false,
        [aimstep] = false,
        [psilent] = false,
        [autofire] = true
    })

    -- cache_process("rage_active", rage_active, in_legit and not fakeduck_ready, false)
    cache_process("on_fakeduck_ph1", flag_limit, ractive and fakeduck_ready, 14)
    cache_process("on_fakeduck_ph2", auto_pistols, ractive and fakeduck_ready, false)
    cache_process("on_fakeduck_ph3", legit_active, ractive and fakeduck_ready, function()
        ui_set(legit_active, false)
        if get_prop(local_player, "m_flDuckAmount") > 0.01 then
            cmd.in_attack = 0
        end
    end)
end)

client.set_event_callback("paint", function()
    local local_player = get_local()

    local aim_active = ui_get(legit_active) and ui_get(legit_key)
    local lowerbody = ui_get(menu.direction) == var_direction[1] and 'Eye yaw' or 'Opposite'

    if not ui_get(menu.enabled) or not ui_get(menu.legit_aa) or not local_player then
        return
    end

    local data = do_legit_aa(local_player)

    if data == nil then
        return
    end

    if not aim_active then
        ui_mset({
            [pitch] = 'Off',
            [yaw_base] = 'Local view',
            [yaw] = '180',
            [yaw_num] = 180,
            [yaw_jitter] = "Off",
            
            [body] = 'Static',
    
            [lby] = lowerbody,
            [limit] = 60,
        })
    
        if not aim_active and data.fraction < 1 then
            if data.fraction < 1 then
                ui_set(body_num, data.var > 0 and 180 or -180)
            end
        end
    end

    -- calculations
    local clamp = function(int, min, max)
        local vl = int

        vl = vl < min and min or vl
        vl = vl > max and max or vl

        return vl
    end

    local round = function(x, n)
        n = math.pow(10, n or 0); x = x * n
        x = x >= 0 and math.floor(x + 0.5) or math.ceil(x - 0.5)
        return x / n
    end

    local valid_lp_ptr = ffi.cast("void***", get_client_entity(ent_list, local_player))
    local get_local_player_animstate = ffi.cast("char*", valid_lp_ptr) + 0x3900
    local animstate = ffi.cast("struct lm_animstate_s**", get_local_player_animstate)[0]

    local body_yaw = get_prop(local_player, "m_flPoseParameter", 11)
    local real_yaw = animstate.feet_yaw + (body_yaw * 118 - 59)

    local max_dsn = round(-clamp_angles(animstate.feet_yaw - real_yaw), 1)

    -- indication
    local i = 0.5
    local text = "AA"
    local percent = 1

    local width, height = renderer_measure_text("+", text)
    local y = renderer_indicator(255, 255, 255, 150, text)

    local state = aim_active and "DISABLED" or data.side
    local end_width = ((width / 2 - 2) / 60) * max_dsn

    renderer_rectangle(10, y + 27, width, 5, 0, 0, 0, not aim_active and 150 or 0)

    if max_dsn > 0 then
        renderer_rectangle(11 + width / 2, y + 28, end_width, 3, 124, 195, 13, not aim_active and 255 or 0)
        renderer_text(11 + width / 2 + end_width, y + 24, 255, 255, 255, not aim_active and 255 or 0, "-", nil, ">")
    else
        end_width = 15 - (end_width * -1)
        end_width = end_width > 15 and 15 or end_width

        renderer_rectangle(10 + end_width, y + 28, width / 2 - end_width, 3, 124, 195, 13, not aim_active and 255 or 0)
        renderer_text(10 + end_width, y + 24, 255, 255, 255, not aim_active and 255 or 0, "-", nil, "<")
    end

    renderer_text(width + 17, y + (10  * i), 255, 255, 255, 255, "-", nil, "MAX DSN: " .. (aim_active and "0" or math_abs(max_dsn)) .. "°"); i = i + 1;
    renderer_text(width + 17, y + (10 * i), 255, 255, 255, 255, "-", nil, "DIR: " .. (aim_active and "EYE YAW" or data.side)); i = i + 1;
end)
