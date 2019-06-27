--[[Copyright 2019 elprice

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.]]--


--I would like to openly state that much of the UI code/design is borrowed or paraphrased from Ivaar's Skillchains addon (in particular the settings logic). 
--Thank you for all your hard work Ivaar. I will gladly remove this addon if you take issue with it.


_addon.name = "partypets"
_addon.author = "Eikken"
_addon.version = "1.1"
_addon.commands = {"pp"}

require('luau')
texts = require('texts')

default = {}
default.UpdateFrequency = 0.2
default.display = {text={size=12,font='Consolas'},pos={x=0,y=0},bg={visible=false}}
settings = config.load(default)
pet_props = texts.new('',settings.display,settings)
data = {}
pets = {}

initialize = function(text, settings)
    if not windower.ffxi.get_info().logged_in then
        return
    end
    local properties = L{}
    properties:append('${petinfo}')
    text:clear()
    text:append(properties:concat('\n'))
end

function colorize_hpp(hpp)
    local temp
    temp = {}

    local red = '\\cs(255,0,0)'
    local yellow = '\\cs(255,255,0)'
    local orange = '\\cs(255,100,0)'
    local grey = '\\cs(169,169,169)'

    if hpp == 0 then
        return '%s%s\\cr':format(grey, 'DEAD')
    elseif hpp < 25 then
        return '%s%s\\cr':format(red, hpp)
    elseif hpp < 50 then 
        return '%s%s\\cr':format(orange, hpp)
    elseif hpp < 75 then 
        return '%s%s\\cr':format(yellow, hpp)
    end

    return hpp
end

function pad_spaces(str, max_len, hpp)
    local default_pad = 4 
    local str_len = string.len(str)
    max_len = max_len == 0 and str_len or max_len --max_len of 0 can happen after death 
    local hpp_len = hpp == 0 and 4 or string.len(hpp) --if hpp = 0 then text should be DEAD which is 4 long
    local total_pad_length = max_len - str_len + default_pad - hpp_len
    local spaces = '                                                           ' -- because why not just in case
    return string.sub(spaces, 0, total_pad_length)
end

function do_stuff()
    local party = windower.ffxi.get_party()
    local petdata = ''
    local max_len = 0
    
    if party.p0 ~= nil then
        for k,v in pairs(party) do
            if type(party[k]) == "table" and party[k].mob ~= nil and party[k].mob.pet_index ~= nil then
                local pet = windower.ffxi.get_mob_by_index(party[k].mob.pet_index)
                if pet ~= nil then
                    pet_info = {}
                    pet_info.owner_index = k
                    pet_info.owner_name = party[k].name
                    pet_info.name = pet.name
                    pet_info.hpp = pet.hpp
                    pet_info.time = os.time()
                    pets[pet_info.owner_name] = pet_info
                    max_len = math.max(max_len, string.len(party[k].name..pet.name))
                end
            end
        end
        for k,v in pairs(pets) do
            if os.time() - pets[k].time < 10 then --keep label for 10s in case out of range or pet died
                --incase pet died between updates
                if type(party[pets[k].owner_index]) == "table" and party[pets[k].owner_index].mob ~= nil and party[pets[k].owner_index].mob.pet_index == nil then
                    pets[k].hpp = 0
                end
                petdata = petdata..pets[k].owner_name.." - "..pets[k].name..":"..pad_spaces(pets[k].owner_name..pets[k].name, max_len, pets[k].hpp)..colorize_hpp(pets[k].hpp).."\n"
            end
        end
        data.petinfo = petdata
        pet_props:update(data)
        pet_props:show()
    elseif party.p0 == nil then
        pet_props:hide()
    end
end


pet_props:register_event('reload', initialize)

windower.register_event('load', function()
    initialize()
    do_loop = do_stuff:loop(settings.UpdateFrequency)
end)

windower.register_event('unload', function()
    data = {}
    pets = {}
    coroutine.close(do_loop)
end)

windower.register_event('zone change', function()
    data = {}
    pets = {}
end)