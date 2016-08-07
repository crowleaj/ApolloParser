--Created by Alex Crowley
--On July 20, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms

local inspect = require "inspect"

require "classann"

--[[
    Establishes what a class is in terms of its hierarchy
--]]
local function applyIsa(classes, class, isa)
  table.insert(isa, class.name)
  class.isa = isa
  for _, class in pairs(class.children) do
    applyIsa(classes, classes[class], deepcopy(isa))
  end
  class.children = nil
end

--[[
    Creates a class hierarchy by lineraizing the classes.
    Assigns to the parent class its direct children then uses
    top level to establish what a class is
--]]
local function linearizeClasses(classes)
  local toplevel = {}
  for name, class in pairs(classes) do
      if class.parent == nil then
        table.insert(toplevel, class)
      else
        table.insert(classes[class.parent].children, name)
      end
  end
  for _, class in pairs(toplevel) do
    applyIsa(classes, class, {})
  end
end

--[[
    Organizes class data from lexer and establishes a hierarchy
]]
function preParseClasses(classes)
  for _, class in pairs(classes) do
    class.traits = {}
    class.children = {}
    for _, arg in ipairs(class.val) do
      local type = arg.type
      if type == "class" then
        class.parent = arg.name
      elseif type == "trait" then
        table.insert(class.traits, arg.name)
      else
        class.body = arg
      end
    end
    class.val = nil
    class.type = nil
  end
  linearizeClasses(classes)
end
























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