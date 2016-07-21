--Created by Alex Crowley
--On July 19, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms

function parseAssignment(line, scope)
  local var = parseValue(line.var)
  scope[var] = line.class
  local nTree = {}
  local type = line.type
  if line.scope == "local" then
    table.insert(nTree,"local ")
  end
    table.insert(nTree, var)
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