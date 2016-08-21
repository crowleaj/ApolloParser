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

  ltable = (
    "[" * ws * 
    (((((lpeg.V"ltable" + lpeg.V"lfunc" + lpeg.V"larith") * ws * "," * ws)^0) * (lpeg.V"ltable" + lpeg.V"lfunc" + lpeg.V"larith"))^-1)  * ws *
    "]" * ws)/ 
      function(...) return {type = "table", val={...}} end,
 
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

--TODO: Will add back
local lprimclassassignment = (lvarnorm * sepNoNL * ((lvarnorm * sepNoNL)^-1) * "=" * sepNoNL * (lstring + lnum) * ws)/
  function(var, prim, val) if val ~= nil then return {type = "const", ctype = prim.val, val = val.val}
  else return {type = "const", ctype = prim.type, val = prim} end end

  lcclass = ("cclass" * ws * lvarnorm * ws * (("of" * ws * (lclasstype * ws))^-1) * (("with" * ws *(((ltraittype * ws * ","* ws)^0) * ltraittype * ws))^-1) * lpeg.V"lclassbody")/
    function(name, ...)   return {type = "cclass", name = name.val, val = {...}} end,

  ltrait = ("trait" * ws * lvarnorm * ws * (("of" * ws * lclasstype * ws)^-1) * (("with" * ws *(((ltraittype * ws * ","* ws)^0) * ltraittype * ws))^-1) * lpeg.V"lclassbody")/
    function(name, ...)
      return {type = "trait", name = name.val, val = {...}}
    end,

  --CONTROL
  lif = 
    ((("if" * ws * lpeg.V"larith" * ws * lpeg.V"lbody")/ function(condition, body) return {type = "if", cond = condition, body = body} end) *
    (((lpeg.P"or" * ws * lpeg.V"larith" * ws * lpeg.V"lbody")/ function(condition, body) return {type = "elseif", cond = condition, body = body} end)^0) *
    (((lpeg.P"else" * ws * lpeg.V"lbody")/ function(body) return {type = "else", body = body} end)^-1))/
      function(...) return {type = "ifblock", val = {...}} end,
    
  lswitch = ("switch(" * ws * lpeg.V"larith" * ws * ")" * ws * "{" *
    ws * ((("case" * ws * lpeg.V"larith" * ws * (lpeg.V"S"^0))/function(case, ...) return {type = "case", cond = case, val = {...}} end)^0) * 
    ((("default" * ws * (lpeg.V"S"^0))/ function(...) return {type = "default", val = {...}} end)^-1) * ws * "}" * ws)/
      function(cond, ...) return {type = "switch", cond = cond, val = {...}} end,
      
  lforloop = ((lforen + lfornorm) * ws * lpeg.V"lbody" * ws)/
    function(iter,body) return {type="forloop", iter = iter, val = {body}} end,