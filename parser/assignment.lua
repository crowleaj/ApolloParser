--Created by Alex Crowley
--On July 19, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms
function parseArithmetic(rhs)
  local type = rhs.type
  if type == "parentheses" then
    return "(" .. parseArithmetic(rhs.val) .. ")"
  elseif type == "constant" or type == "variable" then
    return rhs.val
  else
    if rhs.precedence < 7 or rhs.precedence == 11 then
        return rhs.op .. "(" .. parseArithmetic(rhs.lhs) .. ", "  .. parseArithmetic(rhs.rhs) .. ")"
    elseif rhs.precedence == 10 then
      return rhs.op .. parseArithmetic(rhs.lhs)
    else
      return parseArithmetic(rhs.lhs) .. rhs.op .. parseArithmetic(rhs.rhs)
    end
  end
end

function parseAssignment(line)
  local var = line.name--parseValue(line.var)
  local nTree = {}
  local type = line.type
  if type == "declassignment" then
    if line.scope == "local" then
      table.insert(nTree,"local ")
    end
  end
    table.insert(nTree, var)
    table.insert(nTree, "=")
  if type == "declassignment" or type == "assignment" then
    table.insert(nTree, parseArithmetic(line.val))--parseValue(line.val))
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
