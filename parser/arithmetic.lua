--Created by Alex Crowley
--On November 3, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms

function parseArithmetic(rhs)
  local type = rhs.type
  if type == "parentheses" then
    return "(" .. parseArithmetic(rhs.val) .. ")"
  elseif type == "constant" or type == "variable" then
    return rhs.val
  else
    if rhs.precedence < 7 or rhs.precedence == 11 then
        return rhs.op .. "(" .. parseArithmetic(rhs.lhs) .. ", "  .. parseArithmetic(rhs.rhs) .. ")"
    elseif rhs.precedence == 10 then
      return rhs.op .. parseArithmetic(rhs.lhs)
    else
      return parseArithmetic(rhs.lhs) .. rhs.op .. parseArithmetic(rhs.rhs)
    end
  end
end

function parseAtom(tokens)
  local current = Tokenizer.current(tokens)
  if current.type == "parentheses" then
    current.val = parseArithmeticTree(Tokenizer.new(current.val.val), 1)
    Tokenizer.next(tokens)
    return current
  elseif current.type == "operation" then
    if current.precedence == 10 then
      Tokenizer.next(tokens)
      --We need to give precedence to the exponentiation operator
      return {type = "operation", op = current.val, precedence = 10, lhs = parseArithmeticTree(tokens,11)}
    else
      print("ERROR: binary operation unexpected " .. current.val)
    end
  else
    Tokenizer.next(tokens)
    return current
  end
end

function parseArithmeticTree(tokens, prec)
    local lhs = parseAtom(tokens)
    while true do
        local current = Tokenizer.current(tokens)
        if current == nil or current.type ~= "operation" or
          current.precedence < prec then
            break
        end
        next_prec = current.precedence
        if current.rightassoc == nil then
          next_prec = next_prec + 1
        end
        Tokenizer.next(tokens)
        rhs = parseArithmeticTree(tokens, next_prec)
        lhs = {type = "operation", lhs = lhs, rhs = rhs, op = current.val, precedence = current.precedence}
    end
    return lhs
end
