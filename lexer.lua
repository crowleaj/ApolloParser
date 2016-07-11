--Created by Alex Crowley
--On July 8, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms


require "lpeg"

local ws = ((lpeg.P(" ") + "\n"+"\t")^0)

local lnum = (((lpeg.R("09")^1) * (("." * (lpeg.R("09")^0)) + "")) + ("." * (lpeg.R("09")^1)))/
  function (num) return {type = "numberconst", val = num} end
local lstring = (("'" * ((lpeg.P(1)-"'")^0) * "'") + ('"' * ((lpeg.P(1)-'"')^0) * '"'))/
  function  (string) return {type = "stringconst", val = string}  end


local lconst = (lnum + lstring)
local lvarnorm = ((("_" + lpeg.R("az", "AZ")) * (("_" + lpeg.R("az", "AZ", "09"))^0))/
  function(var) return {type = "variable", val = var} end)
local lvarclass = lpeg.P"this:" * (( ("_" + lpeg.R("az", "AZ")) * (("_" + lpeg.R("az", "AZ", "09"))^0))/
  function(var) return {type = "classvariable", val = var} end)
local lvar = lvarclass + lvarnorm
local lval = lconst + lvar
local lnumval = lnum + lvar

local llocal = ("var" * ws)/"local"
local lglobal = ("gvar" * ws)/"global"

local lcomment = ("--" * ((lpeg.P(1) - "\n")^0) * "\n" * ws)/
  function(...) return {type = "comment", val = ...} end

local ldotref = ("." * lvar)/
    function(ref) return {type = "dotreference", val = ref.val} end

local lfuncvars =  
  ("(" * ws * 
  (
    (((lvar * ws * ","* ws)^0) * lvar) 
    + ws
  ) * ws * 
  ")")/
    function(...)  if ... == "()" then return {} else return {...} end end

local lfornorm = (
  "for" * ws * 
  lvar * ws *
  lpeg.P"from" * ws *
  lnumval * ws *
  lpeg.P"to" * ws * 
  lnumval * ws *
  ((lpeg.P"by" * ws * lnumval)^-1))/
    function (var,first,last,step) return {type = "fornormal", var = var.val, first = first, last = last, step = (step or {type = "numberconst", val = 1})} end

local lforen = (
  "for" * ws * 
  (
    (lvar * ws * "," * ws * lvar)/function(k,v) return {k= k.val, v=v.val} end
    +((lpeg.P"i"+"k")/
      function(index) return {k = index.val, v = "_"} end)
    +((lvar-(lpeg.P"i"+"k"))/
      function(var) return {k = "_", v = var.val} end)
  ) 
  * ws * "in " * ws * 
  lvar * ws *
    (
      (lpeg.P"pairs"/"pairs")
      + (lpeg.P"array"/"ipairs")
  ))/
      function(kv,var,iter) return {type = "forenhanced", vars = kv, var = var.val, iter = iter} end
  
local arithOp = (lpeg.S("*/+-"))/
  function (operator) return {type = "operator",val = operator} end
  
local lcompare = lpeg.C(lpeg.S("<>") + "<=" + ">=" + "==")/
  function (operator) return {type = "comparison",val = operator} end

local opOverload = lpeg.P(
  (lvar * ws * arithOp * "=" * ws * lvar)/
    function (left, op, right)
      return "" .. left .. "=" .. left .. op .. right
    end
  )

local cfg = lpeg.P{
  "S",
  S = ( lcomment + (lpeg.V"lfunccall" * ws) + lpeg.V"ltablelookup"+ lpeg.V"lclass" + lpeg.V"lassignment" + lpeg.V"ldecl" + lpeg.V"lif" + lpeg.V"lforloop")^1, 
  --((lpeg.P(" ") +"\n")^1)/"\n",
  
  lassignment = 
    ((lvar * ws *
      ("=" * ws * (lpeg.V"ltablelookup" + lpeg.V"ltable" + lpeg.V"lfunc" + lpeg.V"larith" + lval)))/
        function(var,val) return {type = "assignment", var = var, val = val} end
      ) *ws,

  ldecl = ((llocal + lglobal) * ws * (lpeg.V"lassignment" + (lvarnorm * ws)))/
    function(scope,assignment) 
     --if type(assignment) == "string" then return {type = "declaration", var = var, val = }
    assignment.type = "declaration" assignment.scope = scope return assignment end,

  lfunccall = ( lvar * ((lpeg.V"lfunccallparams")^1) * ws)/
    function(func, ...) return {type = "functioncall", name = func, args = {...}} end,
  
  lfunc = 
    (lfuncvars  * ws * 
    "{" * ws *  
    ((lpeg.V"S" * ws)^0) * 
    (lpeg.V"lreturnstatement"^-1) * ws *
    lpeg.P"}" * ws)/ function(vars, ... ) return {type="function", vars = vars, val = {...}}   end,
  
  lfunccallparams = 
    ("(" * ws * 
    ((
      (((lpeg.V"ltablelookup" + lpeg.V"lfunccall" + lpeg.V"larith" + lval) * ws * "," * ws)^0) *
      (lpeg.V"ltablelookup" + lpeg.V"lfunccall" + lpeg.V"larith" + lval) * ws)^-1) *
    ")")/
    function(...) local params = {...} if ... == "()" then params = {} end return {type = "params", val = params} end,
  
  lreturnstatement = ("return" * ws * (lpeg.V"ltablelookup" + lpeg.V"ltable" + lpeg.V"lfunc" + lpeg.V"larith" + lval) * ws)/
    function(val) return {type = "return", val = val} end,
  
  larith = 
    ((
      (lpeg.V"lfunccall" + lnumval) * 
      (
        ((ws * arithOp * ws * (lpeg.V"lfunccall" + lnumval))^1)
        + (ws * arithOp * ws * lpeg.V"larithbal")))/
          function ( ... )
            return {type = "arithmetic", val = {...}}
          end
        )
    + lpeg.V"larithbal",

  larithbal = (ws * "(" * ws * (lpeg.V"larith" + lpeg.V"larithbal" + lnumval) * ws * ")" * ws)/
    function(val) return {type = "parentheses", val = val} end,
  
  ltable = (
    "[" * ws * 
    (((((lpeg.V"ltable" + lpeg.V"lfunccall" + lval + lpeg.V"lfunc") * ws* ",")^0) * (lpeg.V"ltable" + lpeg.V"lfunccall" + lval + lpeg.V"lfunc"))^-1)  * ws *
    "]")/ 
      function(...) return {type = "table", val={...}} end,

lforloop = ((lforen + lfornorm) * ws * lpeg.V"lforbody" * ws)/
  function(iter,body) return {type="forloop", iter = iter, val = {body}} end,

lforbody =   
  "{" * ws *  
  ((lpeg.V"S" * ws)^0) * ws * 
  lpeg.P"}" * ws,
  
lbody = (
  "{" * ws *  
  ((lpeg.V"S" * ws)^0) * ws * 
  lpeg.P"}" * ws),
  
lif = 
  "if" * ws * (lpeg.V"lfunccall" + lval) * ws * lcompare * ws * (lpeg.V"lfunccall" + lval) * ws * 
  (
    (lpeg.V"lbody"  * 
       ((lpeg.P"or" * ws * (lpeg.V"lfunccall" + lval) * ws * lcompare * ws * (lpeg.V"lfunccall" + lval) * ws * 
      lpeg.V"lbody")^0) *
      lpeg.P"else" * ws * lpeg.V"lbody"
  )
    + lpeg.P"else" * ws * lpeg.V"lbody"
    + lpeg.V"lbody"
    ),
  
ltablebrackets = ("[" * (lpeg.V"lfunccall" + lpeg.V"ltablelookup" + lval) * "]")/
    function(val) return {type="brackets", val=val} end,

ltablebody = (ldotref + lpeg.V"ltablebrackets" + lpeg.V"lfunccallparams") * (lpeg.V"ltablebody"^-1) ,

ltablelookup = (lvar * lpeg.V"ltablebody" * ws)/
    function(name, ...) return {type = "tablelookup", name = name, val = {...}} end,
lclass = ("class" * ws * lvar * ws * "{" * ws *
(((lpeg.V"lassignment" + lpeg.V"lclassmethod" + lvar) * ws * (lpeg.P","^-1) * ws)^0) *
 ws * "}")/
  function(name,...) return {type = "class", name = name, val = {...}} end,

lclassmethod = (lvar * lfuncvars * lpeg.V"lbody")/
  function(name,vars,...) return {type = "classmethod", name = name, vars = vars, val = {...}} end,
}

function lex(script)
    return lpeg.Ct((cfg)^0):match(script)
end