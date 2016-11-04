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
      return compareTypes(validateArithmetic(exp.lhs), validateArithmetic(exp.rhs))
    end
  end
end
