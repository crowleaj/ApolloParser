--Created by Alex Crowley
--On August 12, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms

inspect = require "inspect"

function contains(list, item)
  for _, v in pairs(list) do
    if item == v then
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