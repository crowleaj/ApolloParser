--Created by Alex Crowley
--On July 19, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms

function parseFunction(fcn)
  local nTree = {}
  table.insert(nTree, "function")
  table.insert(nTree, parseValues(fcn.vars))
  table.insert(nTree, "\n")
  table.insert(nTree, parseFunctionBody(fcn.val))
  table.insert(nTree, "end")
  return table.concat(nTree)
end

function parseFunctionBody(body)
  local nTree = {}
  for _,line in ipairs(body) do
    local type = line.type
    if type == "return" then
      table.insert(nTree, "return ")
      table.insert(nTree, parseValue(line.val))
      table.insert(nTree, "\n")
    else
      table.insert(nTree,parseLine(line))
    end
  end
  return table.concat(nTree)
end