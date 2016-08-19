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

function applyVariableScope(class, parent)
    for _, var in pairs(parent.variablenames) do
        if contains(class.variablenames, var) == false then
            table.insert(class.variablenames, var)
        end
    end
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
        applyVariableScope(class, classes[class.parent])
        table.insert(classes[class.parent].children, name)
      end
  end
  for _, class in pairs(toplevel) do
    applyIsa(classes, class, {"Any"})
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
    preParseBody(class)
  end
  linearizeClasses(classes)
end