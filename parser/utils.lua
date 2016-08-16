--Created by Alex Crowley
--On August 12, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms

inspect = require "inspect"

local function ident(item)
    return item
end

function contains(list, item, ilambda)
  ilambda = ilambda or ident
  for _, v in pairs(list) do
    if item == ilambda(v) then
      return true
    end
  end
  return false
end

--http://stackoverflow.com/questions/1410862/concatenation-of-tables-in-lua
function appendTable(t1,t2)
  local s1 = #t1
  for i=1,#t2 do
      t1[s1+i] = t2[i]
  end
end

--http://lua-users.org/wiki/CopyTable
function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end