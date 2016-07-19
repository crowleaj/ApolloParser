--Created by Alex Crowley
--On July 19, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms

function parseClass(line)
    local nTree = {}
    classvars = {}
    assignments = {}
    methods = {}
    constructor = nil
    for _,v in ipairs(line.val) do
        type = v.type
        if type == "variable" then
        table.insert(classvars, v.val)
        elseif type == "assignment" then
        table.insert(classvars, v.var.val)
        table.insert(assignments, v)
        elseif type == "classmethod" then
        if v.name == line.name then
            constructor = v
        else
            table.insert(methods,v)
        end
        else
        end
    end
    table.insert(nTree, line.name)
    table.insert(nTree, "={\nnew = ")
    if constructor ~= nil then
        --table.insert(constructor.vars, 1, "self")
        table.insert(nTree, parseFunctionVars(constructor.vars))
    else
        table.insert(nTree, "function()\n")
    end
    table.insert(nTree, "this = {")
    if constructor ~= nil then
        for _,v in ipairs(assignments) do
        table.insert(nTree, parseLine(v))
        table.insert(nTree, ",")
        end
        annotateInstanceVariables({vars = classvars, methods = methods}, constructor.vars, constructor.val, "this")
    else
        --annotateInstanceVariables({vars = classvars, methods = methods}, constructor.vars, constructor.val, "this")
    end
    table.insert(nTree, "}\nsetmetatable(this," .. line.name .. ")\n")
        for _,v in ipairs(constructor.val) do
        table.insert(nTree, parseLine(v))
    end
    table.insert(nTree, "return this\nend\n")
    for _,fcn in ipairs(methods) do
        table.insert(nTree, ",")
        table.insert(nTree, fcn.name)
        table.insert(nTree, "=")
        table.insert(fcn.vars, 1, "self")
        annotateInstanceVariables({vars = classvars, methods = methods}, fcn.vars, fcn.val, "self")
        table.insert(nTree, parseFunction(fcn))
    end
    table.insert(nTree, "}\n")
    table.insert(nTree, line.name)
    table.insert(nTree, ".__index=")
    table.insert(nTree, line.name)
    table.insert(nTree, "\n")
    table.insert(nTree, "local ")
    table.insert(nTree, line.name)
    table.insert(nTree, "=")
    table.insert(nTree, line.name)
    table.insert(nTree, ".new\n")
end