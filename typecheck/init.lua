--Created by Alex Crowley
--On November 3, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms

require "typecheck/arithmetic"
require "typecheck/assignment"
require "typecheck/declaration"
require "typecheck/function"
require "typecheck/scope"

local primitives = {bool = 1, char = 2, short = 3, int = 4, long = 5, float = 6, float64 = 7, number = 8, string = -1, Any = 9}
--local reversePrim = {bool, char, short, int, long, float, float64, number, string}
function isPrimitive(type)
  if type.type == "flat" then
    return primitives[type.ctype]
  end
  return 0
end

function precisionLoss(varname, vartype, valtype)
    if primitives[valtype] ~= 8 and (primitives[vartype] < primitives[valtype]) then
        print("WARNING: Potential loss of precision converting assignment of " .. varname .. " from " .. valtype .. " to " .. vartype)
    end
end



--Gets variable name in scope.  Parameter for contains function
function getvarname(var)
    return var.name
end


function compareTypes(t1, t2)
  local prim1 = isPrimitive(t1)
  local prim2 = isPrimitive(t2)
  if  (prim1 and not prim2) or (not prim1 and prim2) then
    print("ERROR: attempt to mix primitive and non-primitive")
    return t1, 1
  elseif prim1 and prim2 then
    if prim1 == 0 or prim2 == 0 then
      print("ERROR: attempt to mix number with string type")
      return prim1, 1
    end
    if prim1 > prim2 then
      return t1, 0
    end
    return t2, 0
  end
end
