--Created by Alex Crowley
--On July 8, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms

require "lexer"

require "classann"

local inspect = require "inspect"

function parseAssignment(rhs)
  local type = rhs.type
  if type == "variable" or type == "classvariable" or type == "numberconst" or type == "stringconst" or type == "operator" then
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
  elseif type == "classreference" then
    local nTree = {}
    --table.insert(nTree, rhs.var)
    table.insert(nTree, ".")
    table.insert(nTree, rhs.val)
    return table.concat(nTree)
  elseif type == "classmethodcall" then
    local nTree = {}
    table.insert(nTree, ":")
    table.insert(nTree, rhs.val)
    table.insert(nTree, parseFunctionArgs(rhs.args))
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

function parseFunctionVars(vars)
  local nTree = {}
  table.insert(nTree, "function(")
    local args = {}
    for _,v in ipairs(vars) do
    table.insert(args, v)
  end
  table.insert(nTree, table.concat(args,","))
  table.insert(nTree, ")\n")
  return table.concat(nTree)
end

function parseFunction(fcn)
  local nTree = {}
  table.insert(nTree, parseFunctionVars(fcn.vars))
  table.insert(nTree, parseFunctionBody(fcn.val))
  table.insert(nTree, "end")
  return table.concat(nTree)
end

function parseFunctionArgs(args)
  local nTree = {}
  table.insert(nTree,"(")
  for _, arg in ipairs(args.val) do
    table.insert(nTree,parseAssignment(arg))
    table.insert(nTree,",")
  end
  if #args.val >0 then 
      table.remove(nTree)
  end
  table.insert(nTree,")")
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
    table.insert(nTree,parseAssignment(line))
    table.insert(nTree, "\n")
  elseif type == "forloop" then
    local iter = line.iter
    type = iter.type 
    table.insert(nTree, "for ")
    if type == "fornormal" then
      table.insert(nTree, iter.var)
      table.insert(nTree, "=")
      table.insert(nTree, iter.first.val)
      table.insert(nTree, ",")
      table.insert(nTree, iter.last.val)
      table.insert(nTree, ",")
      table.insert(nTree, iter.step.val)
    elseif type == "forenhanced" then
      table.insert(nTree, iter.vars.k)
      table.insert(nTree, ",")
      table.insert(nTree, iter.vars.v)
      table.insert(nTree, " in ")
      table.insert(nTree, iter.iter)
      table.insert(nTree, "(")
      table.insert(nTree, iter.var)
      table.insert(nTree, ")")
    end
    table.insert(nTree, " do\n")
    for _,line in ipairs(line.val) do
      table.insert(nTree, parseLine(line))
    end
    table.insert(nTree, "end\n")
  elseif type == "class" then
    classvars = {}
    assignments = {}
    methods = {}
    constructor = nil
    for _,v in ipairs(line.val) do
      type = v.type
      if type == "variable" then
        table.insert(classvars, v.val)
      elseif type == "assignment" then
        table.insert(classvars, v.var.val)
        table.insert(assignments, v)
      elseif type == "classmethod" then
        if v.name == line.name then
          constructor = v
        else
          table.insert(methods,v)
        end
      else
      end
    end
    table.insert(nTree, line.name)
    table.insert(nTree, "={\n__initfunction = ")
    if constructor ~= nil then
      table.insert(constructor.vars, 1, "self")
      table.insert(nTree, parseFunctionVars(constructor.vars))
    else
      table.insert(nTree, "function()\n")
    end
    table.insert(nTree, "this = {")
    if constructor ~= nil then
      for _,v in ipairs(assignments) do
        table.insert(nTree, parseLine(v))
        table.insert(nTree, ",")
      end
        annotateInstanceVariables({vars = classvars, methods = methods}, constructor.vars, constructor.val, "this")
    else
        annotateInstanceVariables({vars = classvars, methods = methods}, constructor.vars, constructor.val, "this")
    end
    table.insert(nTree, "}\nsetmetatable(this, self)\n")
     for _,v in ipairs(constructor.val) do
      table.insert(nTree, parseLine(v))
    end
    table.insert(nTree, "return this\nend\n")
    for _,fcn in ipairs(methods) do
      table.insert(nTree, ",")
      table.insert(nTree, fcn.name)
      table.insert(nTree, "=")
      table.insert(fcn.vars, 1, "self")
      annotateInstanceVariables({vars = classvars, methods = methods}, fcn.vars, fcn.val, "self")
      table.insert(nTree, parseFunction(fcn))
    end
    table.insert(nTree, "}\n")
    table.insert(nTree, line.name)
    table.insert(nTree, ".__index=")
    table.insert(nTree, line.name)
    table.insert(nTree, "\n")
  elseif type == "comment" then
    --print(line.val)
  elseif type == "classinit" then
    if line.scope == "local" then
      table.insert(nTree, "local ")
    end
    table.insert(nTree, line.var)
    table.insert(nTree, "=")
    table.insert(nTree, line.class)
    table.insert(nTree, ":__initfunction")
    table.insert(nTree,"(")
    for _, arg in ipairs(line.args.val) do
        table.insert(nTree,parseAssignment(arg))
        table.insert(nTree,",")
    end
    if #line.args.val >0 then 
      table.remove(nTree)
    end
    table.insert(nTree,")")
    table.insert(nTree, "\n")
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