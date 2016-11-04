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
  line.val = parseArithmeticTree(Tokenizer.new(line.val.val), 1)
  validateArithmetic(line.val)
  return 0
end
