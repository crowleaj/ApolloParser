--Created by Alex Crowley
--On November 3, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms

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
