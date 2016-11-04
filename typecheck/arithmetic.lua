--Created by Alex Crowley
--On November 3, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms

function validateArithmetic(exp)
  local type = exp.type
  if type == "parentheses" then
    return validateArithmetic(exp.val)
  elseif type == "variable" then
    return exp.val, 0
  elseif type == "constant" then
    return exp.ctype, 0
  else
    local prec = exp.precedence
    if prec == 10 then
      return validateArithmetic(exp.lhs)
    else
      local t1, e1 = validateArithmetic(exp.lhs)
      if e1 > 0 then
        return nil, err
      end
      local t2, e2 = validateArithmetic(exp.rhs)
      if e2 > 0 then
        return nil, err
      end
      return compareTypes(t1, t2)
    end
  end
end
