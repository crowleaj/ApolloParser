--Created by Alex Crowley
--On November 3, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms

function checkAssignment(line, scope)
  local var = resolveVariable(line.name, scope)
  if var == nil then
    print("ERROR: undefined variable " .. line.name)
    return 1
  end
  --Build the parse tree since we're not allowed left-recursive grammars
  line.val, err = parseArithmeticTree(Tokenizer.new(line.val.val), 1)
  if err > 0 then
    return err
  end
  local type, err = validateArithmetic(line.val, scope)
  if err > 0 then
    return err
  end
  local _, assignErr = compareTypes(var, type)
  if assignErr > 0 then
    return assignErr
  end
  v1, v2 = isPrimitive(var), isPrimitive(type)
  if v1 and v2 then
    if v1 < v2 then
      print("WARNING: Potential loss of precision converting assignment of " .. line.name .. " from " .. type.ctype .. " to " .. var.ctype)
    end
  end
  return 0
end
