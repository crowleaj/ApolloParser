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

function parseLine(line, scope)
    local type = line.type
    if type == "declaration" then
        return checkDeclaration(line, scope), parseDeclaration(line)
    elseif type == "function" then
        --Functions checked as a declaration, functions are first class!
        return checkDeclaration(line, scope), parseFunction(line)
    elseif type == "comment" then
        return 0
    else
        print("ERROR: unrecognized instruction " .. type)
        return 1
    end
end
function parseFile(file, scope)
    local tree = {"do"}
    scope.file = {variables = {}}
    for _, line in ipairs(file) do
        local err, parsed = parseLine(line, scope)
        if err > 0 then
            return err
        else
            table.insert(tree, parsed)
        end
    end
    table.insert(tree, "end")
    return 0, table.concat(tree, "\n")
end