--Created by Alex Crowley
--On August 20, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms

--[[
    Contains the common preparser for classes and traits that organizes 
    the body into functions, variables and variable instantion order. 
--]]

--[[
  Preparses class and trait body
  Organizes the body into variable and function tables
  Returns:
  a body table of
    variables
    variableorder
    variablenames
    functions
    constructor
--]]
function preParseBody(class)
  local variables = {}
  local variableorder = {}
  local variablenames = {}
  local functions = {}
  for _, line in pairs(class.body) do
    local type = line.type
    if type == "declaration" then
      variables[line.name] = line
      table.insert(variablenames, line.name)
    elseif type == "declassignment" then
      variables[line.name] = line
      table.insert(variablenames, line.name)
      --Important to know the order the variables were assigned in the class or trait
      table.insert(variableorder, line.name)
    --Checks to see if the class name matches the function name.  If so, designates the func as a constructor
    elseif type == "function" then
      if class.name == line.name then
        class.constructor = line
      else
        functions[line.name] = line
      end
    --In the form of Foo:bar to designate which method a class should select for mixin
    elseif type == "functionref" then
      functions[line.name] = line
    else
      print("UNKNOWN Class body" .. type)
    end
  end
  class.variables = variables
  class.variableorder = variableorder
  class.variablenames = variablenames
  class.functions = functions
  --Create an empty constructor if none exists
  class.constructor = class.constructor or {params = {}, returns = {}, body = {}}
  class.body = nil
end