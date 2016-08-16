--Created by Alex Crowley
--On July 19, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms

function parseValues(vars, scope)
  local nTree = {}
  table.insert(nTree, "(")
    local args = {}
    for _,v in ipairs(vars) do
    table.insert(args, parseValue(v, scope))
  end
  table.insert(nTree, table.concat(args,","))
  table.insert(nTree, ")")
  return table.concat(nTree)
end

--TODO: check type
function parseDeclaration(val)
  local nTree = {}
  if val.scope == "local" then
    table.insert(nTree, "local")
  end
  if val.annotation ~= nil then
    table.insert(nTree, val.annotation)
    table.insert(nTree, ".")
  end
  table.insert(nTree, val.name)
  table.insert(nTree, "=")
  if val.type == "declassignment" then
    local type = val.ctype.val
    table.insert(nTree, parseValue(val.val))
    -- if isPrimitive(type) then
      
    -- end
  elseif val.type == "assignment" then
    table.insert(nTree, parseValue(val.val))
  end
  table.insert(nTree, "\n")
  return table.concat(nTree)
end

function parseValue(rhs, scope)
  local type = rhs.type
  --print(type)
  if type == "variable" or type == "classvariable" or type == "numberconst" or type == "operator" then
    if rhs.annotation ~= nil then
      return rhs.annotation .. "." .. rhs.val
    end
    return rhs.val
  elseif type == "constant" then
    if rhs.ctype == "string" then
      return "'" .. rhs.val .. "'"
    else
      return rhs.val
    end
  elseif type == "function" then
    return parseFunction(rhs)
  elseif type == "parentheses" then
    local nTree = {}
    table.insert(nTree, "(")
    table.insert(nTree, parseValue(rhs.val, scope))
    table.insert(nTree, ")")
    return table.concat(nTree)
  elseif type == "arithmetic" then
    local nTree = {}
    for _,op in ipairs(rhs.val) do
      table.insert(nTree, parseValue(op, scope))
    end
    return table.concat(nTree)
  elseif type == "table" then
    local nTree = {}
    table.insert(nTree,"{")
    for _,arg in ipairs(rhs.val) do
         table.insert(nTree,parseValue(arg, scope))
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
    table.insert(nTree, parseValue(rhs.name, scope))
    for _, val in ipairs(rhs.args) do
      table.insert(nTree,"(")
      for _, arg in ipairs(val.val) do
        table.insert(nTree,parseValue(arg, scope))
        table.insert(nTree,",")
      end
      if #val.val >0 then 
        table.remove(nTree)
      end
      table.insert(nTree,")")
    end
    return table.concat(nTree)
  elseif type == "classreference" then
    print("TYPE: " .. scope[rhs.var])
    local nTree = {}
    --table.insert(nTree, rhs.var)
    table.insert(nTree, ".")
    table.insert(nTree, rhs.val)
    return table.concat(nTree)
  elseif type == "cclassreference" then
    local nTree = {}
    --table.insert(nTree, rhs.var)
    table.insert(nTree, ":")
    table.insert(nTree, rhs.val)
    table.insert(nTree, "()")
    return table.concat(nTree)
  elseif type == "classmethodcall" then
    local nTree = {}
    table.insert(nTree, ":")
    table.insert(nTree, rhs.val)
    table.insert(nTree, parseValues(rhs.args))
    return table.concat(nTree)
  else
    print("ERROR Processing value " .. type)
    return "ERR"
  end
end

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