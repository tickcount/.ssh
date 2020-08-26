local hands = { ui.reference('Visuals', 'Colored models', 'Hands') }
local master_switch = ui.new_checkbox('VISUALS', 'Colored models', 'Wireframe hand chams')

local update_time, cache_clr = 0, nil

local arms_material = materialsystem.arms_material
local ui_get, ui_set = ui.get, ui.set
local math_random = math.random

local get_arms_material = function(callback)
    local material = arms_material()

    if material ~= nil then
        return callback(material)
    end
end

local reset = function()
    if cache_clr ~= nil then
        ui_set(hands[4], cache_clr[1], cache_clr[2], cache_clr[3], cache_clr[4])
        cache_clr = nil
    end
end

local set_method = function(method)
    return ({
        [1] = function()
            reset()
            get_arms_material(function(mat)
                local realtime = globals.realtime()
        
                if mat:get_material_var_flag(28) and realtime > update_time then
                    update_time = realtime + 0.5
                    
                    cache_clr = { ui_get(hands[4]) }
                    ui_set(hands[4], cache_clr[1], cache_clr[2], cache_clr[3], math_random(0, 255))
                end
            end)
        end,

        [2] = function()
            reset()
            get_arms_material(function(mat)
                if not ui_get(master_switch) or mat:get_material_var_flag(28) then
                    return
                end

                mat:set_material_var_flag(28, true)
                -- mat:set_material_var_flag(7, true)
            end)
        end
    })[method]()
end

client.set_event_callback('shutdown', reset)
client.set_event_callback('pre_config_save', reset)
client.set_event_callback('pre_render', function() set_method(1) end)
client.set_event_callback('post_render', function() set_method(2) end)
