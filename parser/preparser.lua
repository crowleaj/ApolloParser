--Created by Alex Crowley
--On August 7, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms

require "parser/utils"

require "parser/classpreparse"
require "parser/traitpreparse"

--[[
  Preparses class and trait body
  Organizes the body into variable and function tables
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
      table.insert(variableorder, line.name)
    elseif type == "function" then
      if class.name == line.name then
        class.constructor = line
      else
        functions[line.name] = line
      end
    else
      print(type)
    end
  end
  class.variables = variables
  class.variableorder = variableorder
  class.variablenames = variablenames
  class.functions = functions
  class.body = nil
end

--[[
    First pass of data
    Organizes data into the following categories/scopes:
      global: 
        traits, classes, gfunc, gvar
      file:
        func, var
     Also captures the main function of the file requested to parse

     Returns:
      global, files (list of file scopes), main
--]]
function preParse(tree)

  local global = {traits = {}, classes = {}, functions = {}, variables = {}}
  local files = {}
  local main = nil
  for num,f in ipairs(tree) do
    local file = {functions = {}, variables = {}}
    for _,line in ipairs(f) do
      local type = line.type
      if type == "declassignment" or type == "declaration" then
        if line.scope == "global" then
          table.insert(global.variables, line)
        else
          table.insert(file.variables, line)
        end
      elseif type == "function" then
        if line.name == "main" then
          if num == #tree then
            main = line
          end
        elseif line.scope == "global" then
          table.insert(global.functions, line)
        else
          table.insert(file.functions, line)
        end
      elseif type == "trait" then
        global.traits[line.name] = line
      elseif type == "class" or type == "cclass" then
        global.classes[line.name] = line
      end
    end
    table.insert(files, file)
  end
  preParseClasses(global.classes)
  preParseTraits(global.traits)

  return global, files, main
end