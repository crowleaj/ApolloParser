--Created by Alex Crowley
--On August 7, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms

require "utils"

require "preparser/class"
require "preparser/trait"

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
    local file = {functions = {}, variables = {}, globalfunctions = {}, globalvariables = {}}
    for _,line in ipairs(f) do
      local type = line.type
      if type == "declassignment" or type == "declaration" then
        if line.scope == "global" then
          table.insert(global.variables, line)
          table.insert(file.globalvariables, line)
        else
          table.insert(file.variables, line)
        end
      elseif type == "function" then
        if line.name == "main" then
          if num == #tree then
            file.main = line
            main = line
          end
        elseif line.scope == "global" then
          table.insert(global.functions, line)
          table.insert(file.globalfunctions, line)
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
  --Top level is needed for top-down parsing to ensure no nil references
  global.classtoplevel = preParseClasses(global.classes)
  preParseTraits(global.traits)
  if main == nil then
    print("ERROR: no main function found")
  end
  return global, files, main
end