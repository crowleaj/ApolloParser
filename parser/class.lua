--Created by Alex Crowley
--On July 19, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms

require "classann"

function parseClasses(classes)
    local nTree = {}
    for _, class in pairs(classes) do
        table.insert(nTree, parseClass(class, classes))
    end
    return table.concat(nTree)
end

function parseClass(class, classes)
    class.constructor = class.constructor or {params = {}, returns = {}, body = {}}
    annotateMethod(class.constructor, classes, class.variablenames)
    -- appendTable(inits, class.constructor.body)
    -- class.constructor.body = inits

    local nTree = {}
    table.insert(nTree, class.name)
    table.insert(nTree, "={\nnew = ")
    table.insert(nTree, "function")
    table.insert(nTree, parseValues(class.constructor.params, scope))
    table.insert(nTree, "\n")

    --Class variables instantiation
    table.insert(nTree, "local self = ")
    if class.parent == nil then
        table.insert(nTree, "{")
        for _, init in pairs(class.variableorder) do
            table.insert(nTree, parseLine(class.variables[init]))
            table.insert(nTree, ",") 
        end
        table.insert(nTree, "}")
    else
        table.insert(nTree, class.parent)
        table.insert(nTree, ".new()")
        for _, init in pairs(class.variableorder) do
            table.insert(nTree, parseLine(class.variables[init]))
            table.insert(nTree, ",") 
        end
    end
    table.insert(nTree, "\nsetmetatable(self," .. class.name .. ")\n")

    table.insert(nTree, parseFunctionBody(class.constructor.body))
    --End of constructor, beginnig of function definitions
    table.insert(nTree, "return self\nend\n")
    for _,fcn in pairs(class.functions) do
        table.insert(nTree, ",")
        table.insert(fcn.params, 1, {type = "variable", name = "self"})
        --annotateInstanceVariables({vars = classvars, methods = methods}, fcn.vars, fcn.val, "self")
        table.insert(nTree, parseFunction(fcn))
    end
    --Closing of class definition
    table.insert(nTree, "}\n")
    table.insert(nTree, class.name)
    table.insert(nTree, ".__index=")
    table.insert(nTree, class.name)
    table.insert(nTree, "\n")
    return table.concat(nTree)
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

    if constructor ~= nil then
        for _,v in ipairs(assignments) do
        table.insert(nTree, parseLine(v, scope))
        table.insert(nTree, ",")
        end
        annotateInstanceVariables({vars = classvars, methods = methods}, constructor.vars, constructor.val, "this")
    else
        --annotateInstanceVariables({vars = classvars, methods = methods}, constructor.vars, constructor.val, "this")
    end

        for _,v in ipairs(constructor.val) do
        table.insert(nTree, parseLine(v))
    end

    --[[table.insert(nTree, "local ")
    table.insert(nTree, line.name)
    table.insert(nTree, "=")
    table.insert(nTree, line.name)
    table.insert(nTree, ".new\n")--]]
    return table.concat(nTree)
end