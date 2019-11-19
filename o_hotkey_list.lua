local ALPHA = 255
local dragging = (function()local a={}local b,c,d,e,f,g,h,i,j,k,l,m,n,o;local p={__index={drag=function(self,...)local q,r=self:get()local s,t=a.drag(q,r,...)if q~=s or r~=t then self:set(s,t)end;return s,t end,set=function(self,q,r)local j,k=client.screen_size()ui.set(self.x_reference,q/j*self.res)ui.set(self.y_reference,r/k*self.res)end,get=function(self)local j,k=client.screen_size()return ui.get(self.x_reference)/self.res*j,ui.get(self.y_reference)/self.res*k end}}function a.new(u,v,w,x)x=x or 10000;local j,k=client.screen_size()local y=ui.new_slider("LUA","A",u.." window position",0,x,v/j*x)local z=ui.new_slider("LUA","A","\n"..u.." window position y",0,x,w/k*x)ui.set_visible(y,false)ui.set_visible(z,false)return setmetatable({name=u,x_reference=y,y_reference=z,res=x},p)end;function a.drag(q,r,A,B,C,D,E)if globals.framecount()~=b then c=ui.is_menu_open()f,g=d,e;d,e=ui.mouse_position()i=h;h=client.key_state(0x01)==true;m=l;l={}o=n;n=false;j,k=client.screen_size()end;if c and i~=nil then if(not i or o)and h and f>q and g>r and f<q+A and g<r+B then n=true;q,r=q+d-f,r+e-g;if not D then q=math.max(0,math.min(j-A,q))r=math.max(0,math.min(k-B,r))end end end;table.insert(l,{q,r,A,B})return q,r,A,B end;return a end)()

local active = ui.new_checkbox("VISUALS", "Other ESP", "Hotkey list")
local color_picker = ui.new_color_picker("VISUALS", "Other ESP", "Hotkey list color picker", 89, 119, 239)
local hotkeys_dragging = dragging.new("Hotkeys", 100, 200)

local references = { }
local hotkey_id = {
    "holding",
    "toggled",
    "disabled"
}

local function item_count(tab)
    if tab == nil then return 0 end
    if #tab == 0 then
        local val = 0
        for k in pairs(tab) do
            val = val + 1
        end

        return val
    end

    return #tab
end

local function create_item(tab, container, name, arg, cname)
    local collected = { }
    local reference = { ui.reference(tab, container, name) }

    for i=1, #reference do
        if i <= arg then
            collected[i] = reference[i]
        end
    end

    references[cname or name] = collected
end

local function paint_handler()
    if not ui.get(active) then
        return
    end

    local m_items = { }
    local x_offset, y_offset = 0, 26

    for ref in pairs(references) do
        local current_ref = references[ref]
        local count = item_count(current_ref)

        local active = true
        local state = { ui.get(current_ref[count]) }

        if count > 1 then
            active = ui.get(current_ref[1])
        end

        if active and state[2] ~= 0 and (state[2] == 3 and not state[1] or state[2] ~= 3 and state[1]) then
            m_items[ref] = hotkey_id[state[2]]

            local ms = renderer.measure_text(nil, ref)

            if ms > x_offset then
                x_offset = ms
            end
        end
    end

    if ui.is_menu_open() then
        x_offset = 55
        m_items = {
            ["menu item"] = "state"
        }
    end

    if item_count(m_items) == 0 then
        return
    end

    -- do stuff
    local x, y = hotkeys_dragging:get()
    local w, h = 75 + x_offset, 11 + (15*item_count(m_items))

    local r, g, b, a = ui.get(color_picker)
    local a = ALPHA > a and a or ALPHA

    renderer.rectangle(x, y, w, 20, 0, 0, 0, a)
    renderer.text(x+5, y+3, 255, 255, 255, 255, "", 0, "Hotkeys")

    renderer.rectangle(x, y + 19, w, 2, r, g, b, ALPHA)
    renderer.rectangle(x, y + 20, w, h, 17, 17, 17, a)

    for key, val in pairs(m_items) do
        local key_type = "[" .. val .. "]"

        renderer.text(x + 5, y + y_offset, 255, 255, 255, 255, "", 0, key)
        renderer.text(x + w - renderer.measure_text(nil, key_type) - 5, y + y_offset, 255, 255, 255, 255, "", 0, key_type)

        y_offset = y_offset + 15
    end

    hotkeys_dragging:drag(w, h*2)
end

-- Creating menu items
create_item("RAGE", "Aimbot", "Force safe point", 1, "Safe point")
create_item("RAGE", "Other", "Force body aim", 1)
create_item("RAGE", "Other", "Duck peek assist", 1)
create_item("RAGE", "Other", "Anti-aim correction override", 1, "Resolver override")
create_item("RAGE", "Other", "Double tap", 2)
create_item("AA", "Other", "Slow motion", 2)
create_item("AA", "Other", "On shot anti-aim", 2)
create_item("MISC", "Movement", "Z-Hop", 2)
create_item("MISC", "Movement", "Pre-speed", 2)
create_item("MISC", "Movement", "Blockbot", 2)
create_item("MISC", "Movement", "Jump at edge", 2)
create_item("MISC", "Miscellaneous", "Free look", 1)

-- create_item("MISC", "Miscellaneous", "Ping spike", 2)
create_item("MISC", "Miscellaneous", "Automatic grenade release", 2, "Grenade release")
create_item("VISUALS", "Player ESP", "Activation type", 1, "Visuals")

client.set_event_callback("paint", paint_handler)
