--Created by Alex Crowley
--On July 20, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms

require "preparser/common"

--[[
    Establishes what a class is in terms of its hierarchy.
    An isa table is necessary in order for type checking
--]]
local function applyIsa(classes, class, isa)
  table.insert(isa, class.name)
  class.isa = isa
  for _, class in pairs(class.children) do
    applyIsa(classes, classes[class], deepcopy(isa))
  end
  --class.children = nil
end

--[[
    Applies the variable scope of the parent to the class.
--]]
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
    Returns:
      top level of classes
--]]
local function linearizeClasses(classes)
  local toplevel = {}
  for name, class in pairs(classes) do
      if class.parent == nil then
        table.insert(toplevel, class)
      else
        --Need to know variables that the parent has defined as well
        applyVariableScope(class, classes[class.parent])
        table.insert(classes[class.parent].children, name)
      end
  end
  --Start the recursive isa application beginning at the top level
  for _, class in pairs(toplevel) do
    applyIsa(classes, class, {"Any"})
  end
  return toplevel
end

--[[
    Organizes class data by getting its parent, traits and body then delegates to
    common body preparser and class linearizer
    Returns:
      top level of classes
--]]
function preParseClasses(classes)
  for _, class in pairs(classes) do
    --Create traits and children table to be populated later
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
  return linearizeClasses(classes)
end