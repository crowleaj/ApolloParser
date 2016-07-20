--Created by Alex Crowley
--On July 19, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms

local __varval = 0
function uniquevar()
  __varval = __varval + 1
  return "___var" .. __varval
end

function parseSwitch(line)
    local nTree = {}
    local switchvar = uniquevar()
    table.insert(nTree, parseAssignment({type = "declaration", scope = "local", var = {type = "variable", val = switchvar}, val = line.cond}))
    table.insert(nTree, "if ")
    for _, line in ipairs(line.val) do
      type = line.type 
      if type == "case" then
        table.insert(nTree, parseValue(line.cond))
        table.insert(nTree, "==")
        table.insert(nTree, switchvar)
        table.insert(nTree, " then\n")
        table.insert(nTree, parseFunctionBody(line.val))
        table.insert(nTree, "elseif ")
      else
        table.remove(nTree)
        table.insert(nTree, "else\n")
        table.insert(nTree, parseFunctionBody(line.val))
      end
    end
    if line.val[#line.val].type ~= "default" then
      table.remove(nTree)
    end
    table.insert(nTree,"end\n")
    return table.concat(nTree)
end