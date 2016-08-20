--Created by Alex Crowley
--On July 19, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms

require "classann"

--[[
    Responsible for parsing all the classes.
    Starts by parsing the top level then children so all function references can be resolved properly
--]]
function parseClasses(classes, toplevel)
    local nTree = {}
    for _, class in pairs(toplevel) do
        table.insert(nTree, parseClass(classes, class))

        --Builds a list of children class references of current class then parses them after parent
        local children = {}
        for _, child in pairs(class.children) do
            table.insert(children, classes[child])
        end
        table.insert(nTree, parseClasses(classes, children))
    end
    return table.concat(nTree)
end

--[[
    Parses the individual class
]]
function parseClass(classes, class)


    annotateMethod(classes, class.variablenames, class.constructor)
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
        if fcn.type == "functionref" then
            table.insert(nTree, fcn.name)
            table.insert(nTree, "=")
            table.insert(nTree, fcn.class)
            table.insert(nTree, ".")
            table.insert(nTree, fcn.name)
        else
            annotateMethod(classes, class.variablenames, fcn)
            table.insert(fcn.params, 1, {type = "variable", name = "self"})
            --annotateInstanceVariables({vars = classvars, methods = methods}, fcn.vars, fcn.val, "self")
            table.insert(nTree, parseFunction(fcn))
        end
    end
    --Closing of class definition
    table.insert(nTree, "}\n")
    table.insert(nTree, class.name)
    table.insert(nTree, ".__index=")
    table.insert(nTree, class.name)
    table.insert(nTree, "\n")
    return table.concat(nTree)
end