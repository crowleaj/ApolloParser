
local primitives = {bool = 1, char = 2, short = 3, int = 4, long = 5, float = 6, float64 = 7, number = 8, string = 0}

function isPrimitive(type)
    return (primitives[type] ~= nil)
end

local function precisionLoss(varname, vartype, valtype)
    if primitives[vartype] < primitives[valtype] then
        print("WARNING: Potential loss of precision converting assignment of " .. varname .. " from " .. valtype .. " to " .. vartype)
    end
end

function resolveVariable(varname, locals, scope)
    return locals[varname] or scope.file.variables[varname] or scope.global.variables[varname]
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
        elseif contains(scope.global.variables, name, getvarname) == true then
            print("ERROR: global variable " .. name .. " already declared")
            return 1
        --Local variable declaration followed by global declaration
        elseif contains(scope.file.variables, name, getvarname) == true then
            print("ERROR: global variable " .. name .. " already declared with file scope")
            return 1
        else
            table.insert(scope.global.variables, line)            
        end

    else
        if scope.func ~= nil then
            --Variable already declared in function scope
            if contains(scope.func.variables, name, getvarname) == true then
                print("ERROR: variable " .. name .. " already declared in scope")
                return 1
            else
                table.insert(scope.func.variables, line)
            end
        --Varible already declared in file
        elseif contains(scope.file.variables, name, getvarname) == true then
            print("ERROR: variable " .. name .. " already declared in file")
            return 1
        --Global variable declaration followed by local declaration
        elseif contains(scope.global.variables, name, getvarname) == true then
            print("ERROR: global variable " .. name .. " already declared with global scope")
            return 1
        else
            table.insert(scope.file.variables, line)           
        end

    end
    --No problems
    return 0
end