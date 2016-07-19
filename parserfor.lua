--Created by Alex Crowley
--On July 19, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms

function parseFor(loop)
    local nTree = {}
    local iter = loop.iter
    local type = iter.type 
    table.insert(nTree, "for ")
    if type == "fornormal" then
      table.insert(nTree, iter.var)
      table.insert(nTree, "=")
      table.insert(nTree, iter.first.val)
      table.insert(nTree, ",")
      table.insert(nTree, iter.last.val)
      table.insert(nTree, ",")
      table.insert(nTree, iter.step.val)
    elseif type == "forenhanced" then
      table.insert(nTree, iter.vars.k)
      table.insert(nTree, ",")
      table.insert(nTree, iter.vars.v)
      table.insert(nTree, " in ")
      table.insert(nTree, iter.iter)
      table.insert(nTree, "(")
      table.insert(nTree, iter.var)
      table.insert(nTree, ")")
    end
    table.insert(nTree, " do\n")
    for _,line in ipairs(loop.val) do
      table.insert(nTree, parseLine(line))
    end
    table.insert(nTree, "end\n")
end