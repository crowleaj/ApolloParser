--Created by Alex Crowley
--On July 8, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms

require "lexer"

require "parser/value"
require "parser/assignment"
require "parser/function"
require "parser/ifblock"
require "parser/for"
require "parser/switch"
require "parser/class"

require "classann"

require "parser/queue"

require "parser/preparser"

local inspect = require "inspect"

function parseLine(line, scope)
  local nTree = {}
  local type = line.type
  if type == "assignment" or type == "declaration" or type == "classinit" then
    table.insert(nTree, parseAssignment(line, scope))
  elseif type == "functioncall" then
    table.insert(nTree, parseValue(line, scope))
    table.insert(nTree, "\n")
  elseif type == "tablelookup" then
    table.insert(nTree,parseValue(line, scope))
    table.insert(nTree, "\n")
  elseif type == "forloop" then
    table.insert(nTree, parseFor(line))
  elseif type == "class" then
    table.insert(nTree, parseClass(line))
  elseif type == "cclass" then
    --[[table.insert(nTree, "local ")
    table.insert(nTree, line.name)
    table.insert(nTree, "=")
    table.insert(nTree, line.name)
    table.insert(nTree, ".new\n")--]]
  elseif type == "function" then
    table.insert(nTree, parseFunction(line))
  elseif type == "declassignment" then
    table.insert(nTree, parseDeclaration(line))
  elseif type == "ifblock" then
    table.insert(nTree, parseIfBlock(line))
  elseif type == "switch" then

    table.insert(nTree, parseSwitch(line))
  elseif type == "comment" then
    --print(line.val)
  else
    --print(type)
    print("unrecognized instruction: " .. inspect(line))
  end
  return table.concat(nTree)
end

--Each file will have functions, variables and body, last file will have main




function parse(tree)
  local global, files, main = preParse(tree)

  print(inspect(global))
  local nTree = {}
  local scope = {}
  for _,file in ipairs(files) do
    for _,line in ipairs(file) do
      table.insert(nTree,parseLine(line, scope))
    end
  end
  table.insert(nTree, parseFunction(main))
  table.insert(nTree, "main()")
  return table.concat(nTree)
end 

function loadfile(file)
  local f = io.open(file .. ".ns", "rb")
  local script = f:read("*all")
  f:close()
  return script
end

function runfile(file,output)
  run(loadfile(file),output)
end

function run(script,output)
  local p, classes = lex(script)
  preparseClasses(classes)
  --print(inspect(classes))
  --print(inspect(p))
  p = parse(p)
  if output == true then
      print(p)
  end
  local chunk, err = assert(loadstring(p))
  if chunk == nil then
    print(err)
  else
    chunk()
    io.write "\n"
  end
end