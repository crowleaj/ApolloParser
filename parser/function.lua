--Created by Alex Crowley
--On July 19, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms

function parseFunction(fcn)
  local nTree = {}
  if fcn.scope == "local" then
    table.insert(nTree, "local ")
  end
  table.insert(nTree, fcn.name)
  table.insert(nTree, " = function")

  table.insert(nTree, parseFunctionValues(fcn.params))
  table.insert(nTree, "\n")
  table.insert(nTree, parseFunctionBody(fcn.body))
  table.insert(nTree, "end\n")
  return table.concat(nTree)
end

function parseFunctionValues(vals)
  local nTree = {"("}
  local args = {}
  for _, val in ipairs(vals) do
    table.insert(args, val.name)
  end
  table.insert(nTree,table.concat(args, ","))
  table.insert(nTree, ")")
  return table.concat(nTree)
end

function parseSignature(fcn)
  local params = {}
  for _,v in ipairs(fcn.params) do
    table.insert(params, v.ctype)
  end
  return {params = parms, returns = params.returns}
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