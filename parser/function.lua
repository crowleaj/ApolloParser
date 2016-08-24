--Created by Alex Crowley
--On July 19, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms

--[[
  Parses and validates a function.
  Returns:
    Error code, 0 if successful
    Parsed function
]]
function parseFunction(fcn, scope)
  --Define a new func scope
  scope.func = {variables = {}, returns = fcn.returns, func = scope.func}

  --Build header part of function
  local assignment = {}
  if fcn.scope == "local" then
    table.insert(assignment, "local ")
  end
  table.insert(assignment, fcn.name)
  table.insert(assignment, " = function")

  --Parse and check header
  local err, header = parseFunctionValues(fcn.params, scope)
  table.insert(assignment, header)

  --Build body part of function
  local nTree = {}
  table.insert(nTree, table.concat(assignment))

  --Parse and check body
  local err1, body = parseFunctionBody(fcn.body, scope)
  if body ~= "" then
    table.insert(nTree, body)
  end

  table.insert(nTree, "end")

  --If we see main, add a call to it to initiate the program
  if fcn.name == "main" then
    table.insert(nTree, "main()")
  end

  --Dereference func from the namespace since we are done with it
  scope.func = scope.func.func.func
  return err + err1, table.concat(nTree, "\n")
end

--[[
  Creates the header of the function.
  Adds variables to func scope then creates
  a fresh scope to allow variables to be shadowed
  Returns:
    Concatenated table of parameters
    Error code, 0 if successful
--]]
function parseFunctionValues(vals, scope)
  local nTree = {"("}

  --Build params
  local args = {}
  for _, val in ipairs(vals) do
    table.insert(args, val.name)
    table.insert(scope.func.variables, val)
  end
  table.insert(nTree,table.concat(args, ","))

  table.insert(nTree, ")")

  --Create fresh scope to allow shadowing of parameters
  scope.func = {variables = {}, func = scope.func}

  --Run checker to make sure parameters are valid
  return checkFunctionParameters(vals, scope), table.concat(nTree)
end

function parseSignature(fcn)
  local params = {}
  for _,v in ipairs(fcn.params) do
    table.insert(params, v.ctype)
  end
  return {params = parms, returns = params.returns}
end

--[[
  Parses the body of the function and performs checking.
  Returns:
    Error code, 0 if successful
    Concatenated function body
--]]
function parseFunctionBody(body, scope)
  local nTree = {}
  for _,line in ipairs(body) do
    local type = line.type
    --TODO: revisit return and make sure it is last statement
    if type == "return" then
      table.insert(nTree, "return ")
      table.insert(nTree, parseValue(line.val))
      table.insert(nTree, "\n")
    else
      local err, val = parseLine(line, scope)
      if err > 0 then
        return err
      end
      table.insert(nTree, val)
    end
  end
  return 0, table.concat(nTree, "\n")
end