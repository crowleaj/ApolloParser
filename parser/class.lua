--Created by Alex Crowley
--On July 19, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms

function parseClass(class)
    local inits = {}
    for _, init in pairs(class.variableorder) do
        table.insert(inits, class.variables[init]) 
    end
    class.constructor = class.constructor or {params = {}, returns = {}, body = {}}
    appendTable(inits, class.constructor.body)
    class.constructor.body = inits

    local nTree = {}
    table.insert(nTree, class.name)
end

function pparseClass(line)
    local nTree = {}
    classvars = {}
    assignments = {}
    methods = {}
    constructor = nil
    local scope = {}
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
        table.insert(nTree, "function")
        table.insert(nTree, parseValues(constructor.vars, scope))
        table.insert(nTree, "\n")
    else
        table.insert(nTree, "function()\n")
    end
    table.insert(nTree, "this = {")
    if constructor ~= nil then
        for _,v in ipairs(assignments) do
        table.insert(nTree, parseLine(v, scope))
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
        table.insert(fcn.vars, 1, {type = "variable", val = "self"})
        annotateInstanceVariables({vars = classvars, methods = methods}, fcn.vars, fcn.val, "self")
        table.insert(nTree, parseFunction(fcn))
    end
    table.insert(nTree, "}\n")
    table.insert(nTree, line.name)
    table.insert(nTree, ".__index=")
    table.insert(nTree, line.name)
    table.insert(nTree, "\n")
    --[[table.insert(nTree, "local ")
    table.insert(nTree, line.name)
    table.insert(nTree, "=")
    table.insert(nTree, line.name)
    table.insert(nTree, ".new\n")--]]
    return table.concat(nTree)
end