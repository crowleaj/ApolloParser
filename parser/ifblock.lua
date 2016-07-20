--Created by Alex Crowley
--On July 19, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms

function parseIfBlock(line)
    local nTree = {}
    for _, line in ipairs(line.val) do
      table.insert(nTree, parseCondition(line))
    end
      table.insert(nTree, "end\n")
    return table.concat(nTree)
end

function parseCondition(line)
    local type = line.type
    local nTree = {}
    if type == "if" then
        table.insert(nTree, "if ")
        table.insert(nTree, parseValue(line.cond))
        table.insert(nTree, " then\n")
        table.insert(nTree, parseFunctionBody(line.val))
    elseif type == "elseif" then
        table.insert(nTree, "elseif ")
        table.insert(nTree, parseValue(line.cond))
        table.insert(nTree, " then\n")
        table.insert(nTree, parseFunctionBody(line.val))
    elseif type == "else" then
        table.insert(nTree, "else\n")
        table.insert(nTree, parseFunctionBody(line.val))
    else
        print "ERROR: Unexpected statement in if block"
    end
    return table.concat(nTree)
end