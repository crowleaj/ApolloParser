--Created by Alex Crowley
--On November 3, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms

--[[
    Runs a validation check on function parameters to make sure
    variable names are not duplicated and types are valid
    Returns:
        Error code, 0 if successful
--]]
function checkFunctionParameters(params, scope)
    for i, current in ipairs(params) do
        --TODO: check if type is valid
        for j=i+1,#params,1 do
            if current.name == params[j].name then
                print("ERROR: variable name " .. current.name .. " already defined in function parameters")
                return 1
            end
        end
    end
    return 0
end

function checkFunctionCall(line, scope)
  local call, err = parseFunctionCallTree(line)
  if err > 0 then
    return err
  end
  return validateFunctionCall(line, scope)
end

function validateFunctionCall(line, scope)
  local fcn = resolveVariable(line.name.val, scope)
  if fcn == nil then
    print("ERROR: undefined function " .. line.name.val)
    return 1
  end
  --TODO: Add in currying
  if #fcn.params ~= #line.args[1].val then
    print("ERROR: invalid number of parameters passed to function " .. line.name.val .. ", " .. #fcn.params .. "expected")
    return 1
  end
  for i, param in ipairs(line.args[1].val) do
    --param.val = parseArithmeticTree(Tokenizer.new(param.val),1)
    local type, err = validateArithmetic(param.val, scope)
    if err > 0 then
      return 1
    end
    local _, typeErr = compareTypes(fcn.params[i].ctype, type)
    if typeErr > 0 then
      return 1
    end
    v1, v2 = isPrimitive(fcn.params[i].ctype), isPrimitive(type)
    if v1 and v2 then
      if v1 < v2 then
        print("WARNING: Potential loss of precision converting return value " .. i .. " in function " .. scope.func.func.name .. " from " .. type.ctype .. " to " .. returns[i].ctype)
      end
    end
  end
  return 0
end
