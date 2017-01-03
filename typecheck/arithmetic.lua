--Created by Alex Crowley
--On November 3, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms

function validateArithmetic(exp, scope)
  --print(inspect(exp))
  local type = exp.type
  if type == "parentheses" then
    return validateArithmetic(exp.val, scope)
  elseif type == "variable" then
    var = resolveVariable(exp.val, scope)
    if var == nil then
      print("ERROR: undefined variable " .. exp.val .. " in arithmetic expression")
      return nil, 1
    end
    return var, 0
  elseif type == "constant" then
    return exp.ctype, 0
  elseif type == "functioncall" then
    local fcn = resolveVariable(exp.name.val, scope)
    if fcn == nil then
      print("ERROR: undefined function " .. exp.name.val .. " in arithmetic expression")
      return nil, 1
    end
    return fcn.returns[1], validateFunctionCall(exp, scope)
  elseif type == "array" then
    if #exp.val == 0 then
      print("ERROR: no elements in array")
      return nil, 1
    end
    local e1
    type = validateArithmetic(exp.val[1], scope)
    for index, arrExp in ipairs(exp.val) do
      resType, e1 = validateArithmetic(arrExp, scope)
      if e1 > 0 then
        print("ERROR: problem validating array element " .. index)
        break
      end
      type, e1 = compareTypes(type, resType)
      if e1 > 0 then
        print("ERROR: problem comparinrg array elements")
        break
      end
    end
    return {type = "array", ctype = type}, e1
  else
    local prec = exp.precedence
    if prec == 10 then
      return validateArithmetic(exp.lhs, scope)
    else
      local t1, e1 = validateArithmetic(exp.lhs, scope)
      if e1 > 0 then
        return nil, e1
      end
      local t2, e2 = validateArithmetic(exp.rhs, scope)
      if e2 > 0 then
        return nil, e2
      end
      return compareTypes(t1, t2)
    end
  end
end
