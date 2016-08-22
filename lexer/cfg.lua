--Created by Alex Crowley
--On August 20, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms

--TODO: fix tablelookup grammar to reject all grammars that don't end in function call or catch error in parser
return lpeg.P{
  "S",

  S = (lpeg.V"lvariable" + lpeg.V"lfunc" +  lcomment + linclude + (lpeg.V"lfunccall" * ws) +
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
  ldeclassignment = (lpeg.V"ldecl" * (ws * ("=" * ws * lval) + lpeg.V"ldeclparams") * ws)/
    function(declaration, assignment) declaration.type = "declassignment" declaration.val = assignment return declaration  end,

  lclassdeclassignment = (lpeg.V"lclassdecl" * (ws * ("=" * ws * lval) + lpeg.V"ldeclparams") * ws)/
    function(declaration, assignment) declaration.type = "declassignment" declaration.val = assignment return declaration  end,
  --TODO: Support arithmetic expressions
  lassignment = (lvar * ws * "=" * ws * lval)/
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
    function(var, type) return {name = var.val, ctype = type.ctype} end,

  lfuncparams = lpeg.Ct("(" * ((ws * (lpeg.V"lquicktypes" + lpeg.V"lfuncparam") * ws * 
    (("," * ws * (lpeg.V"lquicktypes" + lpeg.V"lfuncparam"))^0))^-1) * ws * ")" )/functionparams,

  lfuncreturns = (((lpeg.Ct(lpeg.V"ltype") + (lpeg.V"lfuncptrparams")))^-1),

  lfunc = (lpeg.Cs((lpeg.P"func"/"local") + (lpeg.P"gfunc"/"global")) * sepNoNL * lpeg.V"lclassfunc")/
    function(scope, func) 
      func.scope = scope
      return func end,

  lclassfunc = (lvarnorm * lpeg.V"lfuncparams" * ws * lpeg.V"lfuncreturns" * ws * lpeg.V"lbody")/
    noreturnhandle,

  ldeclparams = lpeg.Ct("(" * ws * ((lval * ws * (("," * ws * lval)^0))^-1) * ws * ")" )/
    function(returns) returns = returns or {} returns.type = "params" return returns end,
--((lpeg.Ct(sepNoNL * lval) + lpeg.V"ldeclparams")^-1)

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
  
  lrhs = (lpeg.V"lclassreference"  + lpeg.V"lfunccall" + lval),
  --+ lpeg.V"ltablelookup"
}