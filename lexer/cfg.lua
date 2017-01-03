--Created by Alex Crowley
--On August 20, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms

--[[
  Context free grammar for Apollo.  Builds a parse tree of the result.
--]]
return lpeg.P{
  "S",

  S = (lpeg.V"lvariable" + lpeg.V"lfunc" + lpeg.V"lluafunc" +  lcomment + linclude + (lpeg.V"lfunccall" * ws) +
  lpeg.V"lclass")^1,
--lpeg.V"lcclass" + lpeg.V"ltrait" + lpeg.V"lif" + lpeg.V"lswitch" + lpeg.V"ltablelookup"  + lpeg.V"lforloop"

  --DECLARATIONS
  lclassdecl = (lvarnorm * ws * (lpeg.V"ltype"))/
    function(var, ctype) return {type = "declaration", name = var.val, ctype = ctype} end,

  ldecl = ((llocal + lglobal) * ws * lpeg.V"lclassdecl")/
    function(scope, decl) decl.scope = scope return decl end,

  --VARIABLE DEFINITIONS
  lvariable = (lpeg.V"ldeclassignment" + (lpeg.V"ldecl" * ws)),

  lclassvariable = (lpeg.V"lclassdeclassignment" + (lpeg.V"lclassdecl" * ws)),

  --ASSIGNMENTS and DECLARTIONS that involve ASSIGNMENTS
  ldeclassignment = (lpeg.V"ldecl" * (ws * ("=" * ws * lpeg.V"larith") + lpeg.V"ldeclparams") * ws)/
    function(declaration, assignment) declaration.type = "declassignment" declaration.val = assignment return declaration  end,

  lclassdeclassignment = (lpeg.V"lclassdecl" * (ws * ("=" * ws * lpeg.V"larith") + lpeg.V"ldeclparams") * ws)/
    function(declaration, assignment) declaration.type = "declassignment" declaration.val = assignment return declaration  end,
  --TODO: Support arithmetic expressions
  lassignment = (lvar * ws * "=" * ws * lpeg.V"larith")/
    function(var, val) return {type = "assignment", annotation = var.annotation, name = var.val, val = val} end,

  --VARIABLE TYPES
  lfuncptrparams = lpeg.Ct("(" * ws * ((lpeg.V"ltype" * ws * (("," * ws * lpeg.V"ltype")^0))^-1) * ws * ")" )/
  function(returns) return returns or {} end,

  lfuncptr = ("func" * lpeg.V"lfuncptrparams" * ws * lpeg.V"lfuncreturns")/
    function(params, returns)
      return {type = "function", params = params, returns = returns or {}}
    end,

  ltype = lpeg.V"lfuncptr" + lvartype,


  --FUNCTION SIGNATURE

  --Shorthand signature notation Ex. (foo, bar int)
  lquicktypes = lpeg.Ct(lvarnorm * ws * (("," * ws * lvarnorm * ws)^1) * lpeg.V"ltype" * ws)/quicktype,

  lfuncparam = (lvarnorm * ws * lpeg.V"ltype")/
    function(var, type) return {name = var.val, ctype = type} end,

  lfuncparams = lpeg.Ct("(" * ((ws * (lpeg.V"lquicktypes" + lpeg.V"lfuncparam") * ws *
    (("," * ws * (lpeg.V"lquicktypes" + lpeg.V"lfuncparam"))^0))^-1) * ws * ")" )/functionparams,

  lfuncreturns = (((lpeg.Ct(lpeg.V"ltype") + (lpeg.V"lfuncptrparams")))^-1),

  lfunc = (lpeg.Cs((lpeg.P"func"/"local") + (lpeg.P"gfunc"/"global")) * sepNoNL * lpeg.V"lclassfunc")/
    function(scope, func)
      func.scope = scope
      return func end,
  lluafunc = (lpeg.P"lfunc" * sepNoNL * lvarnorm * ws * lpeg.V"lfuncparams" * ws * lpeg.V"lfuncreturns" * ws)/
  function(name, params, returns)
    return {type = "lfunction", name = name.val, params = params, returns = returns}
  end,

  lclassfunc = (lvarnorm * lpeg.V"lfuncparams" * ws * lpeg.V"lfuncreturns" * ws * lpeg.V"lbody")/
    noreturnhandle,

  ldeclparams = lpeg.Ct("(" * ws * ((lval * ws * (("," * ws * lval)^0))^-1) * ws * ")" )/
    function(returns) returns = returns or {} returns.type = "params" return returns end,
--((lpeg.Ct(sepNoNL * lval) + lpeg.V"ldeclparams")^-1)

  --FUNCTION CALLING
  lcommaseparatedvalues = ((
      ((lpeg.V"larith" * ws * "," * ws)^0) *
      lpeg.V"larith" * ws)^-1)/
    function(...) local params = {...} if ... == "()" then params = {} end return {type = "params", val = params} end,

  lfunccallparams =
    ("(" * ws * lpeg.V"lcommaseparatedvalues" * ")"),

  lfunccall = ( lvar * ((lpeg.V"lfunccallparams")^1) * ws)/
    function(func, ...) return {type = "functioncall", name = func, args = {...}} end,

  --RETURN STATEMENT
  lreturnstatement = ("return" * ws * lpeg.V"lcommaseparatedvalues")/
    function(vals) return {type = "return", val = vals.val} end,
  lparens = ("(" * ws * lpeg.V"larith" * ws * ")")/
    function(val) return {type = "parentheses", val = val} end,
  larith = (ws * (lnotneg^-1) * ws * (lpeg.V"lparens" + lpeg.V"lrhs") * ws * (loperation * ws * (lnotneg^-1) * ws * (lpeg.V"lparens" + lpeg.V"lrhs") * ws)^0)/
    function(...) return {type = "arithmetic", val = {...}} end,

  lbody = lpeg.Ct(
    "{" * ws *
    (((lpeg.V"S" + lpeg.V"lassignment") * ws)^0) * ws *
    (lpeg.V"lreturnstatement"^-1) *
    lpeg.P"}" * ws),

  lclass = ("class" * ws * lvarnorm * ws * (("of" * ws * (lclasstype * ws))^-1) * (("with" * ws *(((ltraittype * ws * ","* ws)^0) * ltraittype * ws))^-1) * lpeg.V"lclassbody")/
    function(name, ...)   return {type = "class", name = name.val, val = {...}} end,

  lclassfuncref = (lvarnorm * ":" * lvarnorm * ws)/
    function(class, func) return {type = "functionref", class = class.val, name = func.val} end,

  lclassbody = lpeg.Ct(("{" * ws * (((lpeg.V"lclassfunc" + lpeg.V"lclassvariable" + lpeg.V"lclassfuncref") * ws)^0) * "}" * ws)^-1),
 --(("with" * ws * ltraittype * ws)

  --CLASS REFERENCES
  lclassreference = (lvar * "->" * lvar)/
    function(var, val) return {type = "classreference", var = var.val, val = val.val} end,

  lclassfunction = (":" * lvar * lpeg.V"lfunccallparams")/
    function(val, args) return {type = "classmethodcall", val = val.val, args = args} end,

  lrhs = (lpeg.V"lclassreference"  + lpeg.V"lfunccall" + lpeg.V"larray" + lval),
  --+ lpeg.V"ltablelookup"

  -- ARRAY ASSIGNMENTS
  larray = ("[" * ws * lpeg.V"lcommaseparatedvalues"  * "]" * ws)/
    function(vals) return {type = "array", val = vals.val} end,
}
