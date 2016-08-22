
function parseLine(line, scope)
    local type = line.type
    if type == "declaration" then
        return checkDeclaration(line, scope), ""
    elseif type == "comment" then
        return 0, ""
    else
        print("ERROR: unrecognized instruction " .. type)
        return 1
    end
end
function parseFile(file, scope)
    scope.file = {variables = {}}
    for _, line in ipairs(file) do
        local err, parsed = parseLine(line, scope)
        if err > 0 then
            return err
        end
    end
end