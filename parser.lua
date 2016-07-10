--Created by Alex Crowley
--On July 8, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms

require "lexer"

local inspect = require "inspect"

function parseAssignment(rhs)
  local type = rhs.type
  if type == "variable" or type == "numberconst" or type == "stringconst" or type == "operator" then
    return rhs.val
  elseif type == "function" then
    return parseFunction(rhs)
  elseif type == "parentheses" then
    local nTree = {}
    table.insert(nTree, "(")
    table.insert(nTree, parseAssignment(rhs.val))
    table.insert(nTree, ")")
    return table.concat(nTree)
  elseif type == "arithmetic" then
    local nTree = {}
    for _,op in ipairs(rhs.val) do
      table.insert(nTree, parseAssignment(op))
    end
    return table.concat(nTree)
  elseif type == "table" then
    local nTree = {}
    table.insert(nTree,"{")
    for _,arg in ipairs(rhs.val) do
         table.insert(nTree,parseAssignment(arg))
         table.insert(nTree,",")
    end
    if #rhs.val > 0 then
      table.remove(nTree)
    end
    table.insert(nTree,"}")
    return table.concat(nTree)
  elseif type == "tablelookup" then
    local nTree = {}
    table.insert(nTree, rhs.name.val)
    for _,val in ipairs(rhs.val) do
      table.insert(nTree,parseTableLookup(val))
    end
    return table.concat(nTree)
  elseif type == "functioncall" then
    local nTree = {}
    table.insert(nTree, parseAssignment(rhs.name))
    for _, val in ipairs(rhs.args) do
      table.insert(nTree,"(")
      for _, arg in ipairs(val.val) do
        table.insert(nTree,parseAssignment(arg))
        table.insert(nTree,",")
      end
      if #val.val >0 then 
        table.remove(nTree)
      end
      table.insert(nTree,")")
    end
    return table.concat(nTree)
  else
    print(type)
    return "ERR"
  end
end

function parseTableLookup(ref)
    local nTree = {}
    local type = ref.type
    if type == "brackets" then
      table.insert(nTree, "[")
      table.insert(nTree, parseAssignment(ref.val))
      table.insert(nTree, "]")
    elseif type == "dotreference" then
      table.insert(nTree, ".")
      table.insert(nTree, ref.val)
    elseif type == "params" then
      table.insert(nTree,"(")
      if #ref.val > 0 then
        for _,v in ipairs(ref.val) do
          table.insert(nTree, parseAssignment(v))
          table.insert(nTree, ",")
        end
          table.remove(nTree)
      end
      table.insert(nTree,")")
    else
      return parseAssignment(ref)
    end
    return table.concat(nTree)
end

function parseFunctionBody(body)
  local nTree = {}
  for _,line in ipairs(body) do
    local type = line.type
    if type == "return" then
      table.insert(nTree, "return ")
      table.insert(nTree, parseAssignment(line.val))
      table.insert(nTree, "\n")
    else
      table.insert(nTree,parseLine(line))
    end
  end
  return table.concat(nTree)
end

function parseFunction(fcn)
  local nTree = {}
  table.insert(nTree, "function(")
  for _,v in ipairs(fcn.vars) do
    table.insert(nTree, v.val)
    table.insert(nTree, ",")
  end
  if #fcn.vars > 0 then
    table.remove(nTree)
  end
  table.insert(nTree, ")\n")
  table.insert(nTree, parseFunctionBody(fcn.val))
  table.insert(nTree, "end")
  return table.concat(nTree)
end

function parseLine(line)
  local nTree = {}
  local type = line.type
  if type == "assignment" then
    table.insert(nTree, parseAssignment(line.var))
    table.insert(nTree, "=")
    table.insert(nTree, parseAssignment(line.val))
    table.insert(nTree, "\n")
  elseif type == "declaration" then
  if line.scope == "local" then
    table.insert(nTree,"local ")
  end
    table.insert(nTree, line.var.val)
    table.insert(nTree, "=")
    table.insert(nTree, parseAssignment(line.val))
    table.insert(nTree, "\n")
  elseif type == "functioncall" then
    table.insert(nTree, parseAssignment(line))
    table.insert(nTree, "\n")
  elseif type == "tablelookup" then
    return parseAssignment(line)
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
  print(table.concat(nTree))
end 

function runfile(file,output)
  local f = io.open(file, "rb")
  local script = f:read("*all")
  f:close()
  run(script,output)
end

function run(script,output)
  local p = lex(script)
  for _, inst in ipairs(p) do
    local type = inst.type
    print(inspect(inst))
    if type == "comment" then
    elseif type == "assignment" then
      --print("assignmnt: " .. "var: " .. inspect(inst.var) .. "val: " .. inspect(inst.val))
    end
  end
  parse(p)
  if output == true then
      --print(p)
  end
  --[[local chunk, err = assert(loadstring(p))
  if chunk == nil then
    print(err)
  else
    chunk()
    io.write "\n"
  end--]]
end