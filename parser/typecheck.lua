
local primitives = {bool = 1, char = 2, short = 3, int = 4, long = 5, float = 6, float64 = 7, number = 8, string = 0}

function isPrimitive(type)
  print(inspect(type))
    return type.ctype == "flat" and (primitives[type] ~= nil)
end

local function precisionLoss(varname, vartype, valtype)
    if primitives[valtype] ~= 8 and (primitives[vartype] < primitives[valtype]) then
        print("WARNING: Potential loss of precision converting assignment of " .. varname .. " from " .. valtype .. " to " .. vartype)
    end
end

-- function resolveVariable(varname, locals, scope)
--     return locals[varname] or scope.file.variables[varname] or scope.global.variables[varname]
-- end

function resolveVariable(varname, scope)
  local func = scope.func
  local count = 1
  while func ~= nil do
    if func.variables[varname] ~= nil then
      return func.variables[varname]--count
    end
    func = func.func
    count = count + 1
  end
  if scope.file.variables[varname] ~= nil then
    return scope.file.variables[varname]--count + 1
  elseif scope.global.variables[varname] ~= nil then
    return scope.global.variables[varname]--count + 2
  else
    return nil
  end

end

function checkFunction(body, returns, scope)
    locals = {}
    for _, line in pairs(body) do
        local type = line.type
        if type == "declassignment" then
            if locals[line.name] ~= nil then
                print("ERROR: variable " .. line.name .. " already defined locally as " .. locals[line.name].ctype.val)
                return 1
            end
            if line.ctype.type == "flat" then
                type = line.ctype.ctype
                if isPrimitive(type) then
                    if type == "string" then
                        if line.val.type == "constant" then
                            if line.val.ctype ~= "string" then
                                print("ERROR: invalid conversion of " .. line.name .. " from string to " .. line.val.ctype)
                                return 1
                            end
                        end
                    else
                        local ctype
                        if line.val.type == "constant" then
                            ctype = line.val.ctype
                        elseif line.val.type == "variable" then
                            ctype = resolveVariable(line.val.val, locals, scope)
                            if ctype == nil then
                                print("ERROR: undefined variable " .. line.val.val .. " in assignment of " .. line.name)
                                return 1
                            elseif ctype.type ~= "flat" then
                                print("ERROR: improper type TODO used")
                                return 1
                            else
                                ctype = ctype.ctype
                            end
                        end
                        if ctype == "string" then
                            print("ERROR: invalid conversion of " .. line.name .. " from ".. type .. " to string")
                            return 1
                        end
                        precisionLoss(line.name, type, ctype)
                    end
                    locals[line.name] = line.ctype
                end
            end

        end
    end
    --print(inspect(locals))
    return 0
end

function parseTree(exp, prec)
    local type = exp.type
    if type == "arithmetic" then
        for _, v in ipairs(exp.val) do
            print(inspect(exp))
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

--[[
    Gets the return types from the innermost function.
    Needed because func is treated as a new "scope" in the sense
    that variables undefined in current scope are free to be defined.
    Parsing a function creates a scope with function parameters  and returns then defines a "clean" func scope
    Returns:
        Return types of innermost function
--]]
function getReturns(scope)
    local func = scope.func
    while func.returns == nil do
        func = func.func
    end
    return func.returns
end

--Gets variable name in scope.  Parameter for contains function
function getvarname(var)
    return var.name
end

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

--[[
    Runs a validation check on a declaration to make sure the declaration is valid.
    Also updates the scope where the declaration occured
    Returns:
        Error code, 0 if successful
--]]
function checkDeclaration(line, scope)
    local name = line.name
    if line.scope == "global" then
        --Global variable declared in class or function
        if scope.func ~= nil then
            print("ERROR: global variable " .. name .. " must be declared in outermost scope")
            return 1
        --Global variable already declared
      elseif scope.global.variables[line.name] ~= nil then
            print("ERROR: global variable " .. name .. " already declared")
            return 1
        --Local variable declaration followed by global declaration
      elseif scope.file.variables[line.name] ~= nil then
            print("ERROR: global variable " .. name .. " already declared with file scope")
            return 1
        else
            scope.global.variables[line.name] = line.ctype
        end

    else
        if scope.func ~= nil then
            --Variable already declared in function scope
            if scope.func.variables[line.name] ~= nil then
                print("ERROR: variable " .. name .. " already declared in scope")
                return 1
            else
                scope.func.variables[line.name] = line.ctype
                --table.insert(scope.func.variables, line)
            end
        --Varible already declared in file
      elseif scope.file.variables[line.name] ~= nil then
            print("ERROR: variable " .. name .. " already declared in file")
            return 1
        --Global variable declaration followed by local declaration
      -- elseif scope.global.variables[line.name] ~= nil then
      --       print("ERROR: variable " .. name .. " already declared with global scope")
      --       return 1
        else
            scope.file.variables[line.name] = line.ctype
        end

    end
    --No problems
    return 0
end

function compareTypes(t1, t2)
  local prim1 = isPrimitive(t1)
  local prim2 = isPrimitive(t2)
  if  (prim1 and not prim2) or (not prim1 and prim2) then
  end
end

function validateArithmetic(exp)
  local type = exp.type
  if type == "parentheses" then
    return validateArithmetic(exp.val)
  elseif type == "variable" then
    return exp.val, 0
  elseif type == "constant" then
    return exp.ctype, 0
  else
    print(type)
    local prec = exp.precedence
    if prec == 10 then
      return validateArithmetic(exp.lhs)
    else
      return compareTypes(validateArithmetic(exp.lhs), validateArithmetic(exp.rhs))
    end
  end
end

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
