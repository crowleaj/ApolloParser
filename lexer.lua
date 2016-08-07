--Created by Alex Crowley
--On July 8, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms


require "lpeg"

local includes = {}
local classes = {}

local ws = ((lpeg.P(" ") + "\r" + "\n" + "\t")^0)
local sepNoNL = ((lpeg.P(" ") + "\r" + "\t")^1)
local sep = ((lpeg.P(" ") + "\r" + "\n" + "\t")^1)

local lcomment = ("--" * ((lpeg.P(1) - "\n")^0) * "\n" * ws)/
  function(...) return {type = "comment", val = ...} end

local lnum = (lpeg.P"-"^-1) * (((lpeg.R("09")^1) * (("." * (lpeg.R("09")^0)) + "")) + ("." * (lpeg.R("09")^1)))/
  function(num) return {type = "numberconst", val = num} end

local lstring = (("'" * (((lpeg.P(1)-"'")^0)/function(string) return string end) * "'") + ('"' * (((lpeg.P(1)-'"')^0)/function(string) return string end) * '"'))/
  function(string) return {type = "stringconst", val = string}  end

local lconst = (lnum + lstring)

local lkeywords = (lpeg.P"this" + "trait" + "if" + "or" + "else" + "switch" + "case" + "default" + "for" + "in" + "class" + "cclass" + "var" + "gvar" + "func" + "gfunc") * sep

local lvarnorm = ((("_" + lpeg.R("az", "AZ")) * (("_" + lpeg.R("az", "AZ", "09"))^0))-lkeywords)/
  function(var) return {type = "variable", val = var} end

local lvarclass = lpeg.P"this->" * (lvarnorm/
  function(var) var.type = "classvariable" return var end)

local lvar = lvarclass + lvarnorm

local lval = lconst + lvar

local lnumval = lnum + lvar

local llocalvar = lvarnorm/function(val) return {type = "local", ctype = val.val} end

local lpointer = ("*" * ws * lvarnorm)/function(val) return {type = "pointer", ctype = val.val} end 

local lmanaged = (lpointer * ws * lpeg.C(lpeg.P"owner" + "shared" + "weak"))/function(val, type) return {type = type, val = val.ctype} end

local larray = ("()" * lvarnorm)/function(val) return {type = "array", ctype = val.val} end

local lmap = ("[]" * lvarnorm)/function(val) return {type = "map", ctype = val.val} end

local lvartype = lmap + larray + llocalvar

local llocal = ("var" * ws)/"local"
local lglobal = ("gvar" * ws)/"global"

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
    function(var, first, last, step) return {type = "fornormal", var = var.val, first = first, last = last, step = (step or {type = "numberconst", val = 1})} end

local lforen = (
  "for" * ws * 
  (
    ((lvarnorm * ws * "," * ws * lvarnorm)/function(k,v) return {k= k.val, v=v.val} end)
    +((lpeg.P"i"+"k")/
      function(index) return {k = index.val, v = "_"} end)
    +((lvar-(lpeg.P"i"+"k"))/
      function(var) return {k = "_", v = var.val} end)
  ) 
  * ws * "in " * ws * 
  lpeg.V"lrhs" * ws *
    (
      (lpeg.P"pairs"/"pairs")
      + (lpeg.P"array"/"ipairs")
  ))/
      function(kv, var, iter) return {type = "forenhanced", vars = kv, var = var.val, iter = iter} end

local arithOp = (lpeg.S("*/+-") + (lpeg.P"||"/" or ") + (lpeg.P"&&"/" and ") + lpeg.S("<>") + "<=" + ">=" + "==" + (lpeg.P"!="/"~="))/
  function(operator) return {type = "operator", val = operator} end


local opOverload = lpeg.P(
  (lvar * ws * arithOp * "=" * ws * lvar)/
    function(left, op, right)
      return "" .. left .. "=" .. left .. op .. right
    end
  )

local linclude = (lpeg.P"include" * sepNoNL * lstring * ws)/
  function(include) table.insert(includes, include.val) end

local lparent = lvarnorm/function(var) return {type = "parent", val = var.val} end

local lprimclassassignment = (lvarnorm * sepNoNL * ((lvarnorm * sepNoNL)^-1) * "=" * sepNoNL * (lstring + lnum) * ws)/
  function(var, prim, val) if val ~= nil then return {type = "const", ctype = prim.val, val = val.val}
  else return {type = "const", ctype = prim.type, val = prim} end end

local ltypedec = (lvarnorm * sepNoNL * lvarnorm * ws)/
  function(var, type) return {type = "typedec", ctype = type.val, var = var.val} end

local lclasstype = lvarnorm/function(var) return {type = "class", name = var.val} end
local ltraittype = lvarnorm/function(var) return {type = "trait", name = var.val} end
--TODO: fix tablelookup grammar to reject all grammars that don't end in function call or catch error in parser
local cfg = lpeg.P{
  "S",

  S = (lpeg.V"lfunc" + lpeg.V"ltrait" + lcomment + linclude + lpeg.V"lif" + lpeg.V"lswitch" + lpeg.V"lclassinit" + (lpeg.V"lfunccall" * ws) + lpeg.V"ldeclassignment" + 
  lpeg.V"ltablelookup"  + lpeg.V"lcclass" + lpeg.V"lclass" + lpeg.V"lvariable" + lpeg.V"lforloop")^1, 
 
  lfuncptrparams = lpeg.Ct("(" * ws * ((lpeg.V"ltype" * ws * (("," * ws * lpeg.V"ltype")^0))^-1) * ws * ")" )/
    function(returns) return returns or {} end,
  
  lfuncreturns = (((lpeg.Ct(lpeg.V"ltype") + (lpeg.V"lfuncptrparams")))^-1),

  lfuncptr = ("func" * lpeg.V"lfuncptrparams" * ws * lpeg.V"lfuncreturns")/
    function(params, returns)
      return {type = "function", params = args, returns = returns or {}}
    end,
  
  ltype = lpeg.V"lfuncptr" + lvartype,

  lfuncparam = (lvarnorm * ws * lpeg.V"ltype")/
    function(var, type) return {name = var.val, ctype = type.ctype} end,
  
  lquicktypes = lpeg.Ct(lvarnorm * ws * (("," * ws * lvarnorm * ws)^1) * lvarnorm * ws)/
    function(types) local type = types[#types].val types[#types] = nil
      local t = {type = "quicktypes"}
      for _,v in ipairs(types) do 
        v.type = type
        table.insert(t, {name = v.val, type = type})
      end
      return t 
    end,

  lfuncparams = lpeg.Ct("(" * ((ws * (lpeg.V"lquicktypes" + lpeg.V"lfuncparam") * ws * (("," * ws * (lpeg.V"lquicktypes" + lpeg.V"lfuncparam"))^0))^-1) * ws * ")" )/
    function(params) params = params or {} 
      local t = {}
      for _, v in ipairs(params) do
        if v.type == "quicktypes" then
          appendTable(t, v)
        else
          table.insert(t, v)
        end
      end
      return t
    end,

  lfunc = (lpeg.Cs((lpeg.P"func"/"local") + (lpeg.P"gfunc"/"global")) * sepNoNL * lvarnorm * lpeg.V"lfuncparams" * ws * lpeg.V"lfuncreturns" * ws * lpeg.V"lbody")/
    function(scope, name, params, returns, body) 
      if body == nil then
        body = returns
        returns = {}
      end
    return {type = "function", scope = scope, name = name.val, params = params, returns = returns, body = body} end,

  ldeclassignment = (lpeg.V"ldecl" * (ws * ("=" * ws * lval) + lpeg.V"ldeclparams") * ws)/
    function(declaration, assignment) declaration.type = "declassignment" declaration.val = assignment return declaration  end,

  ldeclparams = lpeg.Ct("(" * ws * ((lval * ws * (("," * ws * lval)^0))^-1) * ws * ")" )/
    function(returns) returns = returns or {} returns.type = "params" return returns end,
--((lpeg.Ct(sepNoNL * lval) + lpeg.V"ldeclparams")^-1)
  ldecl = ((llocal + lglobal) * ws * lvarnorm * ws * lvarnorm)/
    function(scope, var, ctype) return {type = "declaration", scope = scope, name = var.val, ctype = ctype} end,

  lvariable = (lpeg.V"ldeclassignment" + (lpeg.V"ldecl" * ws)),

  lfunccall = ( lvar * ((lpeg.V"lfunccallparams")^1) * ws)/
    function(func, ...) return {type = "functioncall", name = func, args = {...}} end,
  

  lfuncvars = "(" * lvarnorm * ")",
  
  lfunccallparams = 
    ("(" * ws * 
    ((
      ((lpeg.V"larith" * ws * "," * ws)^0) *
      lpeg.V"larith" * ws)^-1) *
    ")")/
    function(...) local params = {...} if ... == "()" then params = {} end return {type = "params", val = params} end,
  
  lreturnstatement = ("return" * ws * lpeg.V"larith" * ws)/
    function(val) return {type = "return", val = val} end,
  
  larith = 
    ((
      (lpeg.V"lrhs") * 
      (
        ((ws * arithOp * ws * lpeg.V"lrhs")
        + (ws * arithOp * ws * lpeg.V"larithbal"))^0))/
          function ( ... )
            return {type = "arithmetic", val = {...}}
          end
        )
    + lpeg.V"larithbal",

  larithbal = (ws * "(" * ws * (lpeg.V"larith" + lpeg.V"larithbal" + lnumval) * ws * ")" * ws)/
    function(val) return {type = "parentheses", val = val} end,
  
  ltable = (
    "[" * ws * 
    (((((lpeg.V"ltable" + lpeg.V"lfunc" + lpeg.V"larith") * ws * "," * ws)^0) * (lpeg.V"ltable" + lpeg.V"lfunc" + lpeg.V"larith"))^-1)  * ws *
    "]" * ws)/ 
      function(...) return {type = "table", val={...}} end,

lforloop = ((lforen + lfornorm) * ws * lpeg.V"lbody" * ws)/
  function(iter,body) return {type="forloop", iter = iter, val = {body}} end,
  
lbody = lpeg.Ct(
  "{" * ws *  
  ((lpeg.V"S" * ws)^0) * ws * 
  (lpeg.V"lreturnstatement"^-1) *
  lpeg.P"}" * ws),
  
lif = 
  ((("if" * ws * lpeg.V"larith" * ws * lpeg.V"lbody")/ function(condition, body) return {type = "if", cond = condition, body = body} end) *
  (((lpeg.P"or" * ws * lpeg.V"larith" * ws * lpeg.V"lbody")/ function(condition, body) return {type = "elseif", cond = condition, body = body} end)^0) *
  (((lpeg.P"else" * ws * lpeg.V"lbody")/ function(body) return {type = "else", body = body} end)^-1))/
    function(...) return {type = "ifblock", val = {...}} end,
  
  ltablebrackets = ("[" * (lpeg.V"lfunccall" + lpeg.V"ltablelookup" + lval) * "]")/
      function(val) return {type="brackets", val=val} end,

  ltablebody = (lpeg.V"lclassfunction" + lpeg.V"lcclassreference" + ldotref + lpeg.V"ltablebrackets" + lpeg.V"lfunccallparams") * (lpeg.V"ltablebody"^-1) ,

  ltablelookup = (lvar * lpeg.V"ltablebody" * ws)/
      function(name, ...) return {type = "tablelookup", name = name, val = {...}} end,

  lclassassignment = (lvarnorm * sepNoNL * lvarnorm * lpeg.V"lfunccallparams" * ws)/
    function(var, type, params) return {type = "classinit", ctype = type.val, var = var.val, val = params} end,
--[[
  * "{" * ws *
  (((lpeg.V"lclassassignment" + lpeg.V"lclassmethod" + lprimclassassignment + ltypedec) * ws * (lpeg.P","^-1) * ws)^0) *
  --(((lpeg.V"lassignment" + lpeg.V"lclassmethod" + ltypedec + lvar) * ((ws * (lpeg.P"," + "\n") * ws * (lpeg.V"lassignment" + lpeg.V"lclassmethod" + ltypedec + lvar))^0))^-1) *
  ws * "}" * ws
  --classes[name.val] = {{type = "class"}, ...}
--]]
  lclass = ("class" * ws * lvarnorm * ws * (("of" * ws * (lclasstype * ws))^-1) * (("with" * ws *(((ltraittype * ws * ","* ws)^0) * ltraittype * ws))^-1) )/
    function(name, ...)   return {type = "class", name = name.val, val = {...}} end,

 --(("with" * ws * ltraittype * ws)
  ltrait = ("trait" * ws * lvarnorm * ws * (("of" * ws * lclasstype * ws)^-1) * (("with" * ws *(((ltraittype * ws * ","* ws)^0) * ltraittype * ws))^-1))/
    function(name, ...)
      return {type = "trait", name = name.val, val = {...}}
    end,

  lclassmethod = (lvar * lfuncvars * lpeg.V"lbody")/
    function(name, vars, ...) return {type = "classmethod", name = name.val, vars = vars, val = {...}} end,

  lglobalclassinit = ("G_" * lpeg.V"lclassinit")/
    function(var) var.scope = "global" return var end,

  lclassinit = lpeg.V"lglobalclassinit" + ((lvar * ws * lvar * lpeg.V"lfunccallparams" * ws)/
    function(class, var, params) return {type = "classinit", scope = "local", class = class.val, var = var, args = params} end) ,

  lclassreference = (lvar * "->" * lvar)/
    function(var, val) return {type = "classreference", var = var.val, val = val.val} end,

  lcclassreference = (":>" * lvar)/
    function(val) return {type = "cclassreference", val = val.val} end,  

  lclassfunction = (":" * lvar * lpeg.V"lfunccallparams")/
    function(val, args) return {type = "classmethodcall", val = val.val, args = args} end,

  lcclass = ("cclass" * ws * lvar * ws * ((":" * ws * (((lparent * ws * ","* ws)^0) * lparent))^-1) * ws * "{" * ws *
    (((lpeg.V"ldeclassignment" + lpeg.V"lclassmethod" + ltypedec + lvar) * ws * (lpeg.P","^-1) * ws)^0) *
    ws * "}" * ws)/
      function(name, ...) classes[name.val] = {{type = "cclass"}, ...} return {type = "cclass", name = name.val} end,

  lswitch = ("switch(" * ws * lpeg.V"larith" * ws * ")" * ws * "{" *
    ws * ((("case" * ws * lpeg.V"larith" * ws * (lpeg.V"S"^0))/function(case, ...) return {type = "case", cond = case, val = {...}} end)^0) * 
    ((("default" * ws * (lpeg.V"S"^0))/ function(...) return {type = "default", val = {...}} end)^-1) * ws * "}" * ws)/
      function(cond, ...) return {type = "switch", cond = cond, val = {...}} end,

  lrhs = (lpeg.V"lclassreference" + lpeg.V"ltablelookup" + lpeg.V"lfunccall" + lval),
}
local inspect = require"inspect"
--http://stackoverflow.com/questions/1410862/concatenation-of-tables-in-lua
function appendTable(t1,t2)
  local s1 = #t1
  for i=1,#t2 do
      t1[s1+i] = t2[i]
  end
end

local function lexdeps(script, parsed)
  parsed[script] = 1
  local tree = {lpeg.Ct(ws * (cfg)^0):match(script)}
  while #includes ~= 0 do
    local incl = includes
    includes = {}
    for _,v in ipairs(incl) do
      if parsed[v] == nil then
        print(v)
        appendTable(tree, lexdeps(loadfile(v), parsed)) 
      end
    end
  end
  return tree
end

function lex(script)
  local parseTree = lexdeps(script,{})
  local classtrees = classes
  classes = {}
  return parseTree, classtrees
end