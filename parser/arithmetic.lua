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
    return parseValue(rhs)
  elseif type == "functioncall" then
    return parseValue(rhs)
  elseif type == "array" then
  --  print(inspect(rhs))
    return "{" .. parseValues(rhs.val) .. "}"
  elseif type == "arrayref" then
    print(inspect(rhs))
    local nTree = {rhs.array}
    for _, v in ipairs(rhs.val) do
      table.insert(nTree, parseArithmetic(v))
    end
    return table.concat(nTree)
  elseif type == "index" then
    return "[" .. parseArithmetic(rhs.val)  .. "]"
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

--[[
Parses an "Atom", or node in the parse tree.
This can either be one side of a binary operator or a unary argument
--]]
function parseAtom(tokens)
  local current = Tokenizer.current(tokens)
  if current.type == "parentheses" then
    current.val = parseArithmeticTree(Tokenizer.new(current.val.val), 1)
    Tokenizer.next(tokens)
    return current, 0
  elseif current.type == "array" then
    for k, _ in ipairs(current.val) do
      current.val[k] = parseArithmeticTree(Tokenizer.new(current.val[k].val), 1)
    end
    return current, 0
  elseif current.type == "operation" then
    --Unary operator
    if current.precedence == 10 then
      Tokenizer.next(tokens)
      --We need to give precedence to the exponentiation operator
      return {type = "operation", op = current.val, precedence = 10, lhs = parseArithmeticTree(tokens,11)}, 0
    else
      print("ERROR: binary operation unexpected " .. current.val)
      return nil, 1
    end
  elseif current.type == "functioncall" then
      return parseFunctionCallTree(current)
  else
    Tokenizer.next(tokens)
    return current, 0
  end
end

--[[
  Parses the tree of an arithmetic expression.
--]]
function parseArithmeticTree(tokens, prec)
    local lhs, err = parseAtom(tokens)
    if err > 0 then
      return nil, err
    end
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
        rhs, err = parseArithmeticTree(tokens, next_prec)
        if err > 0 then
          return nil, err
        end
        lhs = {type = "operation", lhs = lhs, rhs = rhs, op = current.val, precedence = current.precedence}
    end
    return lhs, 0
end

function parseFunctionCallTree(call)
  for i, param in ipairs(call.args[1].val) do
    param.val, err = parseArithmeticTree(Tokenizer.new(param.val),1)
    if err > 0 then
      return nil, err
    end
  end
  return call, 0
end
