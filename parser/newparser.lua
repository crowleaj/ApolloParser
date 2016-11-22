--Created by Alex Crowley
--On November 3, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms

--[[
    Parses a declaration.
    Returns:
        Parsed declaration
]]
function parseDeclaration(line)
    local tree = {}
    if line.scope == "local" then
        table.insert(tree, "local")
        table.insert(tree, line.name)
    else
        return
    end
    return table.concat(tree, " ")
end

--[[
    Validates and parses a statement with respect to its current scope.
    Does not run parser if validator fails.
    Returns:
        Parsed statement
        Error code, 0 if successful
]]
function parseLine(line, scope)
    local type = line.type
    if type == "declaration" then
        local err = checkDeclaration(line, scope)
        if err > 0 then
          return nil, err
        end
        return parseDeclaration(line), err
    elseif type == "assignment" then
        local err = checkAssignment(line, scope)
        if err > 0 then
          return nil, err
        end
        return parseAssignment(line, scope), err
    elseif type == "declassignment" then
      local err = checkDeclaration(line, scope) + checkAssignment(line, scope)
      if err > 0 then
        return nil, err
      end
        return parseAssignment(line), err
    elseif type == "function" then
        --Functions checked as a declaration, functions are first class!
        return parseFunction(line, scope)
    elseif type == "lfunction" then
        scope.global.variables[line.name] = {type = "function", params = {}, returns = line.returns}
          for _, val in ipairs(line.params) do
            table.insert(scope.global.variables[line.name].params, val)
          end
        return nil, 0
    elseif type == "functioncall" then
      local err = checkFunctionCall(line, scope)
      if err > 0 then
        return nil, err
      end
      return parseValue(line), 0
    elseif type == "comment" then
        return nil, 0
    else
        print("ERROR: unrecognized instruction " .. type)
        return nil, 1
    end
end

--[[
    Parses and validates a file.
    Returns:
     Error code, 0 if successful
     Parsed file
]]
function parseFile(file, scope)
    --Encapsulate file
    local tree = {"do"}
    --Create scope for file
    scope.file = {variables = {}}

    --Parse body
    for _, line in ipairs(file) do
        local parsed, err = parseLine(line, scope)
        if err > 0 then
            return err
        else
            table.insert(tree, parsed)
        end
    end

    table.insert(tree, "end")
    return 0, table.concat(tree, "\n")
end
