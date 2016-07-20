--Created by Alex Crowley
--On July 8, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms

require "lexer"

require "parser/value"
require "parser/function"
require "parser/ifblock"
require "parser/for"
require "parser/switch"
require "parser/class"
require "classann"

local inspect = require "inspect"

function parseTableLookup(ref)
    local nTree = {}
    local type = ref.type
    if type == "brackets" then
      table.insert(nTree, "[")
      table.insert(nTree, parseValue(ref.val))
      table.insert(nTree, "]")
    elseif type == "dotreference" then
      table.insert(nTree, ".")
      table.insert(nTree, ref.val)
    elseif type == "params" then
      table.insert(nTree,"(")
      if #ref.val > 0 then
        for _,v in ipairs(ref.val) do
          table.insert(nTree, parseValue(v))
          table.insert(nTree, ",")
        end
          table.remove(nTree)
      end
      table.insert(nTree,")")
    else
      return parseValue(ref)
    end
    return table.concat(nTree)
end

function parseAssignment(line)
  local nTree = {}
  local type = line.type
  if line.scope == "local" then
    table.insert(nTree,"local ")
  end
    table.insert(nTree, parseValue(line.var))
    table.insert(nTree, "=")
  if type == "declaration" or type == "assignment" then
    table.insert(nTree, parseValue(line.val))
  elseif type == "classinit" then
    table.insert(nTree, line.class)
    table.insert(nTree, ".new")
    table.insert(nTree,"(")
    for _, arg in ipairs(line.args.val) do
        table.insert(nTree,parseValue(arg))
        table.insert(nTree,",")
    end
    if #line.args.val >0 then 
      table.remove(nTree)
    end
    table.insert(nTree,")")
  else
    print("ERROR: Invalid declaration type")
  end
  table.insert(nTree, "\n")
  return table.concat(nTree)
end

function parseLine(line)
  local nTree = {}
  local type = line.type
  if type == "assignment" or type == "declaration" or type == "classinit" then
    table.insert(nTree, parseAssignment(line))
  elseif type == "functioncall" then
    table.insert(nTree, parseValue(line))
    table.insert(nTree, "\n")
  elseif type == "tablelookup" then
    table.insert(nTree,parseValue(line))
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
  elseif type == "ifblock" then
    table.insert(nTree, parseIfBlock(line))
  elseif type == "switch" then
    table.insert(nTree, parseSwitch(line))
  elseif type == "comment" then
    --print(line.val)
  else
    print(type)
    --print("unrecognized instruction: " .. inspect(line))
  end
  return table.concat(nTree)
end

function parse(tree)
  local nTree = {}
  for _,line in ipairs(tree) do
    table.insert(nTree,parseLine(line))
  end
  return table.concat(nTree)
end 

function runfile(file,output)
  local f = io.open(file, "rb")
  local script = f:read("*all")
  f:close()
  run(script,output)
end

function run(script,output)
  local p = lex(script)
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