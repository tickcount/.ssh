local script = {
    _debug = false,

    menu = { "AA", "Anti-aimbot angles" --[[ (Other) ]] },
    conditions = { "Default", "Running", "Slow motion", "Air", "Manual" },

    yaw_base = { "Local view", "At targets" },
    jitter_type = { "Off", "Offset", "Center", "Random", "Body yaw" },

    fr_type = { "Off", "Basic", "Inverted" },

    balance_aa = { "[*] Anti-balance adjust", "Balance: Left side", "Balance: Right side" },
}

function script:call(func, name, ...)
    if func == nil then
        return
    end

    local end_name = name[2] or ""

    if name[1] ~= nil then
        end_name = end_name ~= "" and (end_name .. " ") or end_name
        end_name = end_name .. "\n " .. name[1]
    end

    return func(self.menu[1], self.menu[2], end_name, ...)
end

local active = script:call(ui.new_checkbox, { "afa_active", "Fake angles" })
local switch_hk = script:call(ui.new_hotkey, { "afa_hotkey", "Fake angles hotkey" }, true)

local indicator = script:call(ui.new_checkbox, { "afa_indication", "Anti-aim indication" })
local indicator_picker = script:call(ui.new_color_picker, { "afa_indication_color_picker", "Color picker" }, 130, 156, 212, 255)

local manual_aa = script:call(ui.new_checkbox, { "afa_manual", "Manual anti-aims" })
local arrow_dst = script:call(ui.new_slider, { "afa_manual_arrow_distance", nil }, 1, 100, 12, true, "%")
local picker = script:call(ui.new_color_picker, { "afa_manual_color_picker", "Color picker" }, 130, 156, 212, 255)

local manual_left_dir = script:call(ui.new_hotkey, { "afa_manual_left", "Left direction" })
local manual_right_dir = script:call(ui.new_hotkey, { "afa_manual_right", "Right direction" })
local manual_backward_dir = script:call(ui.new_hotkey, { "afa_manual_backward", "Backward direction" })

local manual_state = script:call(ui.new_slider, { "afa_manual_state", nil }, 0, 3, 0)
local label = script:call(ui.new_label, { "afa_label", "Current condition: unknown" })
local condition = script:call(ui.new_combobox, { "afa_condition", nil }, script.conditions)

local edge_data = { }
local itr_history = "UNKNOWN"

local edge_count = { [1] = 7, [2] = 12, [3] = 15, [4] = 19, [5] = 23, [6] = 28, [7] = 29 }
local inv_freestanding = (function()local a=90;local b=function(c,d,e,f)local g=math.atan((d-f)/(c-e))return g*180/math.pi end;local h=function(c,d)local i,j,k,l=nil;j=math.sin(math.rad(d))l=math.cos(math.rad(d))i=math.sin(math.rad(c))k=math.cos(math.rad(c))return k*l,k*j,-i end;local m=function(n,o,p,q,r,s,t)local c,d,e=entity.get_prop(n,"m_vecOrigin")if c==nil then return-1 end;local u=function(v,w,x)local y=math.sqrt(v*v+w*w+x*x)if y==0 then return 0,0,0 end;local z=1/y;return v*z,w*z,x*z end;local A=function(B,C,D,E,F,G)return B*E+C*F+D*G end;local H,I,J=u(c-r,d-s,e-t)return A(H,I,J,o,p,q)end;local K=function(c,d)local L,M=math.rad(c),math.rad(d)local N,O,P,Q=math.sin(L),math.cos(L),math.sin(M),math.cos(M)return O*Q,O*P,-N end;local R=function(S,n,...)local T,U,V=entity.get_prop(S,"m_vecOrigin")local W,X=client.camera_angles()local Y,Z,_=entity.hitbox_position(S,0)local a0,a1,a2=entity.get_prop(n,"m_vecOrigin")local a3=nil;local a4=math.huge;if entity.is_alive(n)then local a5=b(T,U,a0,a1)for a6,a7 in pairs({...})do local a8,a9,aa=h(0,a5+a7)local ab=T+a8*55;local ac=U+a9*55;local ad=V+80;local ae,af=client.trace_bullet(n,a0,a1,a2+70,ab,ac,ad)local ag,ah=client.trace_bullet(n,a0,a1,a2+70,ab+12,ac,ad)local ai,aj=client.trace_bullet(n,a0,a1,a2+70,ab-12,ac,ad)if af<a4 then a4=af;if ah>af then a4=ah end;if aj>af then lowestdamage=aj end;if T-a0>0 then a3=a7 else a3=a7*-1 end elseif af==a4 then return 0 end end end;return a3 end;local ak=function()local S=entity.get_local_player()local al,am,an=entity.get_prop(S,"m_vecOrigin")if S==nil or al==nil then return end;local ao=entity.get_players(true)local ap,aq=client.camera_angles()local ar,as,at=K(ap,aq)local au=-1;local av=0;for aw=1,#ao do local ax=ao[aw]if entity.is_alive(ax)then local ay=m(ax,ar,as,at,al,am,an)if ay>au then au=ay;av=ax end end end;if av~=0 then local az=R(S,av,-90,90)if az~=0 then a=az end;if a<0 then return-180 elseif a>0 then return 180 end end end;return{process=ak}end)()

-- REFERENCE
local aa_active = ui.reference("AA", "Anti-aimbot angles", "Enabled")
local pitch = ui.reference("AA", "Anti-aimbot angles", "Pitch")
local base = ui.reference("AA", "Anti-aimbot angles", "Yaw base")
local yaw, yaw_num = ui.reference("AA", "Anti-aimbot angles", "Yaw")
local yaw_jt, yaw_jt_num = ui.reference("AA", "Anti-aimbot angles", "Yaw jitter")
local body, body_num = ui.reference("AA", "Anti-aimbot angles", "Body yaw")
local limit = ui.reference("AA", "Anti-aimbot angles", "Fake yaw limit")
local lower_body_yaw = ui.reference("AA", "Anti-aimbot angles", "Lower body yaw target")
local fr_bodyyaw = ui.reference("AA", "Anti-aimbot angles", "Freestanding body yaw")
local fr, fr_hk = ui.reference("AA", "Anti-aimbot angles", "Freestanding")
local edge_yaw = ui.reference("AA", "Anti-aimbot angles", "Edge yaw")
local slowmo, slowmo_key = ui.reference("AA", "Other", "Slow motion")

local onshot, onshot_hk = ui.reference("AA", "Other", "On shot anti-aim")
local dtap, dtap_hk = ui.reference("RAGE", "Other", "Double tap")

local menu_data = {
    ["Default"] = {
        base = script:call(ui.new_combobox, { "afa_default_yaw_base", "Yaw base" }, script.yaw_base),

        body_lean = script:call(ui.new_slider, { "afa_default_body_lean", "Body lean" }, 0, 100, 55, true, "%"),
        body_lean_inv = script:call(ui.new_slider, { "afa_default_body_lean_inverse", nil }, 0, 100, 55, true, "%"),

        limit = script:call(ui.new_slider, { "afa_default_yaw_limit", "Fake yaw limit" }, 0, 180, 180, true, "°"),

        yaw_jitter = script:call(ui.new_combobox, { "afa_default_yaw_jitter", "Yaw jitter" }, script.jitter_type),
        yaw_jitter_val = script:call(ui.new_slider, { "afa_default_yaw_jitter_value", nil }, -180, 180, 0, true, "°"),
        yaw_jitter_dsync = script:call(ui.new_checkbox, { "afa_default_yaw_jitter_dsync", "Disable jitter synchronization" }),

        ubl = script:call(ui.new_multiselect, { "afa_default_979_force", "Balance anti-aim" }, script.balance_aa),
        ubl_l_val = script:call(ui.new_slider, { "afa_default_anti979_lvalue", "Anti-balance offset" }, 0, 30, 30, true, "°"),
        ubl_r_val = script:call(ui.new_slider, { "afa_default_anti979_rvalue", nil }, 0, 30, 30, true, "°"),

        freestanding = script:call(ui.new_combobox, { "afa_default_freestanding", "Freestanding body direction" }, script.fr_type),
        opposite = script:call(ui.new_checkbox, { "afa_default_opposite", "Opposite body direction" }),
    },

    ["Running"] = {
        base = script:call(ui.new_combobox, { "afa_running_yaw_base", "Yaw base" }, script.yaw_base),
        
        body_lean = script:call(ui.new_slider, { "afa_running_body_lean", "Body lean" }, 0, 100, 55, true, "%"),
        body_lean_inv = script:call(ui.new_slider, { "afa_running_body_lean_inverse", nil }, 0, 100, 55, true, "%"),

        limit = script:call(ui.new_slider, { "afa_running_yaw_limit", "Fake yaw limit" }, 0, 180, 180, true, "°"),

        yaw_jitter = script:call(ui.new_combobox, { "afa_running_yaw_jitter", "Yaw jitter" }, script.jitter_type),
        yaw_jitter_val = script:call(ui.new_slider, { "afa_running_yaw_jitter_value", nil }, -180, 180, 0, true, "°"),
        yaw_jitter_dsync = script:call(ui.new_checkbox, { "afa_running_yaw_jitter_dsync", "Disable jitter synchronization" }),

        freestanding = script:call(ui.new_combobox, { "afa_running_freestanding", "Freestanding body direction" }, script.fr_type),
        opposite = script:call(ui.new_checkbox, { "afa_running_opposite", "Opposite body direction" }),
    },

    ["Slow motion"] = {
        base = script:call(ui.new_combobox, { "afa_slowmo_yaw_base", "Yaw base" }, script.yaw_base),
        
        body_lean = script:call(ui.new_slider, { "afa_slowmo_body_lean", "Body lean" }, 0, 100, 55, true, "%"),
        body_lean_inv = script:call(ui.new_slider, { "afa_slowmo_body_lean_inverse", nil }, 0, 100, 55, true, "%"),

        limit = script:call(ui.new_slider, { "afa_slowmo_yaw_limit", "Fake yaw limit" }, 0, 180, 180, true, "°"),

        yaw_jitter = script:call(ui.new_combobox, { "afa_slowmo_yaw_jitter", "Yaw jitter" }, script.jitter_type),
        yaw_jitter_val = script:call(ui.new_slider, { "afa_slowmo_yaw_jitter_value", nil }, -180, 180, 0, true, "°"),
        yaw_jitter_dsync = script:call(ui.new_checkbox, { "afa_slowmo_yaw_jitter_dsync", "Disable jitter synchronization" }),

        freestanding = script:call(ui.new_combobox, { "afa_slowmo_freestanding", "Freestanding body direction" }, script.fr_type),
        opposite = script:call(ui.new_checkbox, { "afa_slowmo_opposite", "Opposite body direction" }),
    },

    ["Air"] = {
        base = script:call(ui.new_combobox, { "afa_air_yaw_base", "Yaw base" }, script.yaw_base),
        
        body_lean = script:call(ui.new_slider, { "afa_air_body_lean", "Body lean" }, 0, 100, 55, true, "%"),
        body_lean_inv = script:call(ui.new_slider, { "afa_air_body_lean_inverse", nil }, 0, 100, 55, true, "%"),

        limit = script:call(ui.new_slider, { "afa_air_yaw_limit", "Fake yaw limit" }, 0, 180, 180, true, "°"),

        yaw_jitter = script:call(ui.new_combobox, { "afa_air_yaw_jitter", "Yaw jitter" }, script.jitter_type),
        yaw_jitter_val = script:call(ui.new_slider, { "afa_air_yaw_jitter_value", nil }, -180, 180, 0, true, "°"),
        yaw_jitter_dsync = script:call(ui.new_checkbox, { "afa_air_yaw_jitter_dsync", "Disable jitter synchronization" }),

        freestanding = script:call(ui.new_combobox, { "afa_air_freestanding", "Freestanding body direction" }, script.fr_type),
        opposite = script:call(ui.new_checkbox, { "afa_air_opposite", "Opposite body direction" }, script.fr_type),
    },

    ["Manual"] = {
        body_lean = script:call(ui.new_slider, { "afa_manual_body_lean", "Body lean" }, 0, 100, 55, true, "%"),
        body_lean_inv = script:call(ui.new_slider, { "afa_manual_body_lean_inverse", nil }, 0, 100, 55, true, "%"),

        limit = script:call(ui.new_slider, { "afa_manual_yaw_limit", "Fake yaw limit" }, 0, 180, 180, true, "°"),

        yaw_jitter = script:call(ui.new_combobox, { "afa_manual_yaw_jitter", "Yaw jitter" }, script.jitter_type),
        yaw_jitter_val = script:call(ui.new_slider, { "afa_manual_yaw_jitter_value", nil }, -180, 180, 0, true, "°"),
        yaw_jitter_dsync = script:call(ui.new_checkbox, { "afa_manual_yaw_jitter_dsync", "Disable jitter synchronization" }),

        freestanding = script:call(ui.new_combobox, { "afa_manual_freestanding", "Freestanding body direction" }, script.fr_type),

        ignore_sideways = script:call(ui.new_checkbox, { "afa_manual_ignore_sideways", "Ignore sideways" }),
        opposite = script:call(ui.new_checkbox, { "afa_manual_opposite", "Opposite body direction" }),
    },
}

local ui_get, ui_set = ui.get, ui.set
local entity_get_prop = entity.get_prop
local entity_get_local_player = entity.get_local_player

local client_camera_angles = client.camera_angles
local renderer_measure_text = renderer.measure_text
local renderer_indicator = renderer.indicator
local renderer_rectangle = renderer.rectangle
local renderer_gradient = renderer.gradient
local renderer_text = renderer.text
local math_max = math.max
local math_min = math.min
local math_abs = math.abs
local math_cos = math.cos
local math_sin = math.sin
local math_floor = math.floor

local multi_exec = function(func, list)
    if func == nil then
        return
    end
    
    for ref, val in pairs(list) do
        func(ref, val)
    end
end

local compare = function(tab, val)
    for i = 1, #tab do
        if tab[i] == val then
            return true
        end
    end
    
    return false
end

local get_flags = function(cm)
    local state = "Default"
    local me = entity_get_local_player()

    local flags = entity_get_prop(me, "m_fFlags")
    local x, y, z = entity_get_prop(me, "m_vecVelocity")
    local velocity = math.floor(math.min(10000, math.sqrt(x^2 + y^2) + 0.5))

    if bit.band(flags, 1) ~= 1 or (cm and cm.in_jump == 1) then state = "Air" else
        if velocity > 1 or (cm.sidemove ~= 0 or cm.forwardmove ~= 0) then
            if ui_get(slowmo) and ui_get(slowmo_key) then 
                state = "Slow motion"
            else
                state = "Running"
            end
        else
            state = "Default"
        end
    end

    return {
        velocity = velocity,
        state = state
    }
end

local calculate_body_lean = function(inverted, data)
    local inflean = inverted and ui_get(data[1]) or ui_get(data[2])
    local lean = 59 - (0.59 * inflean)

    return inverted and -lean or lean
end

local bind_system = {
    left = false,
    right = false,
    back = false,
}

function bind_system:update()
    ui_set(manual_left_dir, "On hotkey")
    ui_set(manual_right_dir, "On hotkey")
    ui_set(manual_backward_dir, "On hotkey")

    local m_state = ui_get(manual_state)

    local left_state, right_state, backward_state = 
        ui_get(manual_left_dir), 
        ui_get(manual_right_dir),
        ui_get(manual_backward_dir)

    if  left_state == self.left and 
        right_state == self.right and
        backward_state == self.back then
        return
    end

    self.left, self.right, self.back = 
        left_state, 
        right_state, 
        backward_state

    if (left_state and m_state == 1) or (right_state and m_state == 2) or (backward_state and m_state == 3) then
        ui_set(manual_state, 0)
        return
    end

    if left_state and m_state ~= 1 then
        ui_set(manual_state, 1)
    end

    if right_state and m_state ~= 2 then
        ui_set(manual_state, 2)
    end

    if backward_state and m_state ~= 3 then
        ui_set(manual_state, 3)
    end
end

local bind_callback = function(list, callback, elem)
    for k in pairs(list) do
        if type(list[k]) == "table" and list[k][elem] ~= nil then
            ui.set_callback(list[k][elem], callback)
        end
    end
end

local menu_callback = function(e, menu_call)
    local setup_menu = function(list, current_condition, vis)
        for k in pairs(list) do
            local mode = list[k]
            local active = k == current_condition

            if type(mode) == "table" then
                for j in pairs(mode) do
                    local set_element = true

                    local jit_mode = ui_get(mode.yaw_jitter)
                    local is_body_jitter = jit_mode == script.jitter_type[5]

                    if jit_mode == "Off" and (j == "yaw_jitter_val" or j == "yaw_jitter_dsync") then 
                        set_element = false
                    end

                    if is_body_jitter and j == "opposite" then
                        set_element = false
                    end

                    if k == "Default" then
                        local crooked = ui_get(mode.ubl)

                        local balance_adjust_exploiting = compare(crooked, script.balance_aa[1]) and not is_body_jitter

                        if is_body_jitter and j == "ubl" then
                            set_element = false
                        end

                        if not balance_adjust_exploiting and (j == "ubl_l_val" or j == "ubl_r_val") then
                            set_element = false
                        end
                    end

                    ui.set_visible(mode[j], active and vis and set_element)
                end
            end
        end
    end

    local visible = not ui_get(active) -- or (e == nil and menu_call == nil)
    local manual = ui_get(manual_aa)

    ui_set(switch_hk, "Toggle")

    if e == nil then visible = true end
    if menu_call == nil then
        setup_menu(menu_data, ui_get(condition), not visible)
    end

    multi_exec(ui.set_visible, {
        [indicator] = not visible,
        [indicator_picker] = not visible,
        [manual_aa] = not visible,

        [picker] = not visible,
        [arrow_dst] = not visible and manual,

        [manual_aa] = not visible,
        [manual_left_dir] = not visible and manual,
        [manual_right_dir] = not visible and manual,
        [manual_backward_dir] = not visible and manual,

        [condition] = not visible,
        [label] = not visible,

        [manual_state] = false,
    })

    if script._debug then
        visible = true
    end

    local byaw = ui_get(yaw)
    local bnum = ui_get(body)

    multi_exec(ui.set_visible, {
        [aa_active] = visible,
        [base] = visible,
        
        [yaw] = visible,
        [yaw_num] = visible and byaw ~= "Off",

        [yaw_jt] = visible and byaw ~= "Off", 
        [yaw_jt_num] = visible and byaw ~= "Off" and ui_get(yaw_jt) ~= "Off",

        [body] = visible,
        [body_num] = visible and bnum ~= "Off" and bnum ~= "Opposite",

        [fr_bodyyaw] = visible,
        [lower_body_yaw] = visible,
        [limit] = visible,
        [edge_yaw] = visible,
    })
end

-- Fake angles: Agressive mode
client.set_event_callback("setup_command", function(e)
    if not ui_get(active) then
        return
    end

    itr_history = "UNKNOWN"

    local data = get_flags(e)
    local direction = ui_get(manual_state)
    local state = (direction ~= 0 and not fr_active) and "Manual" or data.state

    local stack = menu_data[state]

    if stack == nil then
        return
    end

    local inverted = ui_get(switch_hk)
    local body_lean = calculate_body_lean(inverted, {
        stack.body_lean,
        stack.body_lean_inv
    })

    local manual_yaw = {
        [0] = direction ~= 0 and "0" or body_lean,
        [1] = -90 + body_lean, [2] = 90 + body_lean,
        [3] = body_lean,
    }

    -- Jitter modes
    local jit_mode = ui_get(stack.yaw_jitter)
    local jit_val = ui_get(stack.yaw_jitter_val)
    local is_body_jitter = jit_mode == script.jitter_type[5]

    -- Balance adjust
    local dt = ui_get(dtap) and ui_get(dtap_hk)

    local ubl = ui_get(menu_data.Default.ubl)
    local ubl_mode = compare(ubl, script.balance_aa[inverted and 2 or 3])

    local balance_adj = {
        lby = "Eye yaw",
        limit = 60
    }

    if state == "Default" and ubl_mode and not is_body_jitter and not dt then
        manual_yaw[0] = manual_yaw[0] / 3
        balance_adj.lby = "Opposite"

        if compare(ubl, script.balance_aa[1]) then
            balance_adj.limit = 30 - ui_get(menu_data.Default[inverted and "ubl_l_val" or "ubl_r_val"])
            itr_history = "ANTI BALANCE"
        else
            itr_history = "EXTENDED"
        end
    end

    -- Log indicator
    if jit_mode ~= "Off" then
        local ptext = "DYNAMIC" .. (is_body_jitter and " BODY" or "") .. " (" .. jit_val .. "°)"
        itr_history = itr_history ~= "UNKNOWN" and itr_history .. " (D:" .. jit_val .. "°)" or ptext
    end

    -- Things
    if state == "Manual" and ui_get(stack.ignore_sideways) then
        manual_yaw[1] = -90
        manual_yaw[2] = 90
    end

    local body_yaw = {
        [false] = "Static",
        [true] = "Opposite"
    }

    local end_data = {
        yaw_num = manual_yaw[direction],
        body_num = is_body_jitter and jit_val or (inverted and -180 or 180),
    }

    if ui_get(stack.freestanding) == script.fr_type[3] then
        manual_yaw[0] = 0
        manual_yaw[3] = 0

        local angle = inv_freestanding:process()

        if angle ~= nil then
            end_data = {
                yaw_num = manual_yaw[direction],
                body_num = angle
            }
        end
    end

    local yaw_limit = ui_get(stack.limit)
    local bnum = end_data.body_num

    if bnum > 0 and bnum > yaw_limit then
        end_data.body_num = yaw_limit
    elseif bnum < 0 and bnum < yaw_limit then
        end_data.body_num = -yaw_limit
    end

    multi_exec(ui_set, {
        [aa_active] = true,

        [yaw] = "180",
        [body] = is_body_jitter and "Jitter" or body_yaw[ui_get(stack.opposite)],
        
        [yaw_num] = end_data.yaw_num,
        [body_num] = end_data.body_num,

        [yaw_jt] = not is_body_jitter and ui_get(stack.yaw_jitter) or "Off",
        [yaw_jt_num] = ui_get(stack.yaw_jitter_dsync) and jit_val or (inverted and jit_val or -jit_val),

        [base] = state == "Manual" and "Local view" or ui_get(stack.base),

        [lower_body_yaw] = balance_adj.lby,
        [limit] = balance_adj.limit,

        [fr_bodyyaw] = ui_get(stack.freestanding) == script.fr_type[2],
        [edge_yaw] = "Off"
    })

    ui_set(label, "Current condition: " .. state)
end)

client.set_event_callback("shutdown", menu_callback)
client.set_event_callback("paint", function()
    menu_callback(true, true)
    bind_system:update()

    local me = entity_get_local_player()
    
    if not entity.is_alive(me) or not ui_get(active) then
        return
    end

    if ui_get(manual_aa) then
        local w, h = client.screen_size()
        local r, g, b, a = ui_get(picker)
    
        local m_state = ui_get(manual_state)
        local fr_active = #ui_get(fr) ~= 0 and ui_get(fr_hk)
        local onshot_active = ui_get(onshot) and ui_get(onshot_hk)
    
        local realtime = globals.realtime() % 3
        local distance = (w/2) / 210 * ui_get(arrow_dst)
        local alpha = not onshot_active and math.floor(math.sin(realtime * 4) * (a/2-1) + a/2) or a
    
        if m_state == 1 or fr_active then renderer.text(w/2 - distance, h / 2 - 1, r, g, b, alpha, "+c", 0, "◄") end
        if m_state == 2 or fr_active then renderer.text(w/2 + distance, h / 2 - 1, r, g, b, alpha, "+c", 0, "►") end
    
        if m_state == 3 and not fr_active then renderer.text(w/2, h / 2 + distance, r, g, b, alpha, "+c", 0, "▼") end
    end

    -- reworked bodyyaw indicator by @sapphyrus
    if ui_get(indicator) then
        local r, g, b, a = ui_get(indicator_picker)

        local normalize_yaw = function(angle)
            angle = (angle % 360 + 360) % 360
            return angle > 180 and angle - 360 or angle
        end
        
        local num_round = function(x, n)
            n = math.pow(10, n or 0); x = x * n
            x = x >= 0 and math.floor(x + 0.5) or math.ceil(x - 0.5)
            return x / n
        end

        local text = "AA"
        local rtext_c = 1
    
        local w, h = renderer_measure_text("+", text)
        local y = renderer_indicator(255, 255, 255, 150, text) + 23
    
        local bar_x, bar_y, bar_w, bar_h = 10, y+2, w, 5
    
        local _, camera_yaw = client_camera_angles()
        local _, rot_yaw = entity_get_prop(me, "m_angAbsRotation")
        local body_pos = entity_get_prop(me, "m_flPoseParameter", 11) or 0
    
        local body_yaw = math_max(-60, math_min(60, num_round(body_pos*120-60+0.5, 1)))
        local percentage = (math_max(-60, math_min(60, body_yaw*1.06))+60) / 120
    
        if camera_yaw ~= nil and rot_yaw ~= nil and 60 < math_abs(normalize_yaw(camera_yaw-(rot_yaw+body_yaw))) then
            percentage = 1-percentage
        end
    
        local center = math_floor(bar_w/2+0.5)
        local start = math_floor(bar_w*percentage)
    
        renderer_rectangle(bar_x, bar_y, bar_w, bar_h, 0, 0, 0, 150)
    
        if percentage > 0.5 then
            renderer_rectangle(bar_x+center+1, bar_y+1, bar_w*(percentage-0.5)-2, bar_h-2, r, g, b, 255)
        else
            renderer_rectangle(bar_x+1+start, bar_y+1, center-start, bar_h-2, r, g, b, 255)
        end
    
        renderer_gradient(bar_x+center, bar_y+1, 1, bar_h-2, 255, 255, 255, a, 140, 140, 140, a, false)
    
        if math_max(-60, math_min(60, math_floor(body_pos*120-60+0.5))) ~= 0 then
            renderer_text(math_max(bar_x, math_min(bar_x+bar_w, bar_x+bar_w*percentage)), y+4, 255, 255, 255, 255, "c-", 0, percentage > 0.5 and ">" or "<")
        end
    
        renderer_text(w + 17, y - 27 + (9  * rtext_c), 255, 255, 255, 255, "-", nil, "MAX DSN: " .. body_yaw .. "°"); rtext_c = rtext_c + 1;
        renderer_text(w + 17, y - 27 + (9 * rtext_c), 255, 255, 255, 255, "-", nil, "ITR: " .. itr_history); rtext_c = rtext_c + 1;
    end
end)

menu_callback(active)
bind_callback(menu_data, menu_callback, "yaw_jitter")
bind_callback(menu_data, menu_callback, "freestanding")
bind_callback(menu_data, menu_callback, "ubl")

ui.set_callback(active, menu_callback)
ui.set_callback(manual_aa, menu_callback)
ui.set_callback(condition, menu_callback)
