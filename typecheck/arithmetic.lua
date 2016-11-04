--Created by Alex Crowley
--On November 3, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms

function validateArithmetic(exp, scope)
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
