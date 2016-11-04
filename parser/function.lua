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
  --TODO: add to file, global or function variable scope

  --Build header part of function
  local assignment = {}
  if fcn.scope == "local" then
    table.insert(assignment, "local ")
  elseif scope.func ~= nil then
      print("ERROR: nested function declared with global scope")
      return 1
  end
  table.insert(assignment, fcn.name)
  table.insert(assignment, " = function")
  --Define a new func scope
  scope.func = {variables = {}, returns = fcn.returns, func = scope.func}



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
    Error code, 0 if successful
    Concatenated table of parameters
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
  Creates the return statement for a function.
  Returns:
    Error code, 0 if successful
    Concatenated return statement
--]]
function parseReturn(line, scope)
  local returns = getReturns(scope)
  if #line.val < #returns then
    --Default to 0 for primitives and null for objects
    for i=#line.val,#returns do
      --print(inspect(line))
    end
  elseif #line.val > #returns then
    print("ERROR: number of returns exceeds function signature value of " .. #returns)
    return 1
  end
  local nTree = {"return "}
  table.insert(nTree, parseValues(line.val))
  return 0, table.concat(nTree)
end

--[[
  Parses the body of the function and performs checking.
  Returns:
    Error code, 0 if successful
    Concatenated function body
--]]
function parseFunctionBody(body, scope)
  local nTree = {}
  local err = 0
  for linenum,line in ipairs(body) do
    local type = line.type
    --TODO: check return
    if type == "return" then
      if linenum < #body then
        print("ERROR: return statement not last in block")
        return 1
      end
      local tree
      err, tree = parseReturn(line, scope)
      table.insert(nTree, tree)
    else
      local err1, val = parseLine(line, scope)
      if err1 > 0 then
        return err1
      end
      table.insert(nTree, val)
    end
  end
  return err, table.concat(nTree, "\n")
end
