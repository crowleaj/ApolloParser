--Created by Alex Crowley
--On July 20, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms

local inspect = require "inspect"

function preparseClass(cname, class)
    local c = {methods = {}, vars = {}, parents = {}, assignments = {}}
    local methods = c.methods
    local vars = c.vars
    local parents = c.parents
    local assignments = c.assignments

    for _,inst in ipairs(class) do
        local type = inst.type
        if type == "typedec" then
           table.insert(vars, inst)
        elseif type == "const" then
            table.insert(vars, inst)
            table.insert(assignments, inst)
        elseif type == "classinit" then
            table.insert(assignments, inst)
        elseif type == "classmethod" then
            if inst.name == cname then
                c.constructor = v
            else
                table.insert(methods, inst)
            end 
        elseif type == "parent" then
            print(inst.val)
            table.insert(parents, inst.val)
        elseif type == "class" or type == "cclass" then
            c.type = type
        else
            print("ERROR: Invalid class body type: " .. type)
        end
    end
end


function preparseClasses(classes)
    local visited = {}
    for cname,class in pairs(classes) do
        if visited[cname] == nil then
            visited[cname] = true
            print(cname)
            class = preparseClass(cname, class)
        end
    end
end