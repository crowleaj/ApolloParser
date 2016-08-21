--[[
    Deprecated code from lexer
--]]
local lpointer = ("*" * ws * lvarnorm)/function(val) return {type = "pointer", ctype = val.val} end 

local lmanaged = (lpointer * ws * lpeg.C(lpeg.P"owner" + "shared" + "weak"))/function(val, type) return {type = type, val = val.ctype} end

  ltablebrackets = ("[" * (lpeg.V"lfunccall" + lpeg.V"ltablelookup" + lval) * "]")/
      function(val) return {type="brackets", val=val} end,

  ltablebody = (lpeg.V"lclassfunction" + lpeg.V"lcclassreference" + ldotref + lpeg.V"ltablebrackets" + lpeg.V"lfunccallparams") * (lpeg.V"ltablebody"^-1) ,

  ltablelookup = (lvar * lpeg.V"ltablebody" * ws)/
      function(name, ...) return {type = "tablelookup", name = name, val = {...}} end,
  
    lcclassreference = (":>" * lvar)/
    function(val) return {type = "cclassreference", val = val.val} end,  

local ldotref = ("." * lvar)/
    function(ref) return {type = "dotreference", val = ref.val} end

local opOverload = lpeg.P(
  (lvar * ws * arithOp * "=" * ws * lvar)/
    function(left, op, right)
      return "" .. left .. "=" .. left .. op .. right
    end
  )

local lparent = lvarnorm/function(var) return {type = "parent", val = var.val} end

local lprimclassassignment = (lvarnorm * sepNoNL * ((lvarnorm * sepNoNL)^-1) * "=" * sepNoNL * (lstring + lnum) * ws)/
  function(var, prim, val) if val ~= nil then return {type = "const", ctype = prim.val, val = val.val}
  else return {type = "const", ctype = prim.type, val = prim} end end
