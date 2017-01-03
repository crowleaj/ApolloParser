--Created by Alex Crowley
--On July 19, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms


local function populateParams(list, params)
  for _, val in ipairs(params) do
    table.insert(list, val)
  end
end

--[[
  Parses and validates a function.
  Returns:
    Error code, 0 if successful
    Parsed function
--]]
function parseFunction(fcn, scope)
  --TODO: add to file, global or function variable scope

  --Build header part of function
  local assignment = {}
  if fcn.scope == "local" then
    if scope.func ~= nil then
      scope.func.variables[fcn.name] = {type = "function", params = {}, returns = fcn.returns}
      populateParams(scope.func.variables[fcn.name].params, fcn.params)
    else
      scope.file.variables[fcn.name] = {type = "function", params = {}, returns = fcn.returns}
      populateParams(scope.file.variables[fcn.name].params, fcn.params)
    end
    table.insert(assignment, "local ")
  elseif scope.func ~= nil then
      print("ERROR: nested function declared with global scope")
      return nil, 1
  else
    scope.global.variables[fcn.name] = {type = "function", params = {}, returns = fcn.returns}
    populateParams(scope.global.variables[fcn.name].params, fcn.params)
  end
  table.insert(assignment, fcn.name)
  table.insert(assignment, " = function")

  --Define a new func scope
  scope.func = {variables = {}, name = fcn.name, params = {}, returns = fcn.returns, func = scope.func}
  for _, val in ipairs(fcn.params) do
    scope.func.variables[val.name] = val.ctype
  end


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

  --print(inspect(scope))
  --Dereference func from the namespace since we are done with it
  scope.func = scope.func.func.func
  return table.concat(nTree, "\n"), err + err1
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
  for i, ret in ipairs(line.val) do
    line.val[i] = parseArithmeticTree(Tokenizer.new(ret.val),1)
    local type, err = validateArithmetic(line.val[i], scope)
    local _, typeErr = compareTypes(returns[i], type)
    if err + typeErr > 0 then
      return 1
    end
    v1, v2 = isPrimitive(returns[i]), isPrimitive(type)
    if v1 and v2 then
      if v1 < v2 then
        print("WARNING: Potential loss of precision converting return value " .. i .. " in function " .. scope.func.func.name .. " from " .. type.ctype .. " to " .. returns[i].ctype)
      end
    end
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
      local val, err1 = parseLine(line, scope)
      if err1 > 0 then
        return err1
      end
      table.insert(nTree, val)
    end
  end
  return err, table.concat(nTree, "\n")
end
