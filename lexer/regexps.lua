--Created by Alex Crowley
--On August 20, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms

ws = ((lpeg.P(" ") + "\r" + "\n" + "\t")^0)
sepNoNL = ((lpeg.P(" ") + "\r" + "\t")^1)
sep = ((lpeg.P(" ") + "\r" + "\n" + "\t")^1)

--KEYWORDS
lkeywords = (lpeg.P"this" + "trait" + "if" + "or" + "else" + "switch" + "case" + "default" + "for" + "in" + "class" + "cclass" + "var" + "gvar" + "func" + "gfunc")

--COMMENTS
lcomment = ("--" * ((lpeg.P(1) - "\n")^0) * "\n" * ws)/
  function(...) return {type = "comment", val = ...} end

--CONSTANTS
linteger = ((lpeg.P"-"^-1) * (lpeg.R("09")^1))/
  function(val) return {type = "constant", ctype = "char", val = val} end

lfloat = ((lpeg.P"-"^-1) * (((lpeg.R("09")^1) * ("." * (lpeg.R("09")^0))) + ((lpeg.R("09")^0) * ("." * (lpeg.R("09")^1)))))/
  function(val) return {type = "constant", ctype = "float64", val = val} end

lnum = lfloat + linteger

lstring = (("'" * (((lpeg.P(1)-"'")^0)/function(string) return string end) * "'") + 
  ('"' * (((lpeg.P(1)-'"')^0)/function(string) return string end) * '"'))/
  function(string) return {type = "constant", ctype = "string", val = string}  end

lconst = (lnum + lstring)

--IDENTIFIERS
lvarnorm = ((("_" + lpeg.R("az", "AZ")) * (("_" + lpeg.R("az", "AZ", "09"))^0))-lkeywords)/
  function(var) return {type = "variable", val = var} end

lvarclass = lpeg.P"this->" * (lvarnorm/
  function(var) var.type = "variable" var.annotation = "self" return var end)

lvar = lvarclass + lvarnorm

--VALUES
lval = lconst + lvar

lnumval = lnum + lvar

--VARIABLE TYPES
llocalvar = lvarnorm/function(val) return {type = "flat", ctype = val.val} end

larray = ("()" * lvarnorm)/function(val) return {type = "array", ctype = val.val} end

lmap = ("[]" * lvarnorm)/function(val) return {type = "map", ctype = val.val} end

lvartype = lmap + larray + llocalvar

--SCOPE SPECIFIERS
llocal = ("var" * ws)/"local"
lglobal = ("gvar" * ws)/"global"

--CLASS/TRAIT for INHERITANCE SPECIFIERS
lclasstype = lvarnorm/function(var) return {type = "class", name = var.val} end
ltraittype = lvarnorm/function(var) return {type = "trait", name = var.val} end

--ARITHMETIC OPERATORS
arithOp = (lpeg.S("*/+-") + (lpeg.P"||"/" or ") + (lpeg.P"&&"/" and ") + lpeg.S("<>") + "<=" + ">=" + "==" + (lpeg.P"!="/"~="))/
  function(operator) return {type = "operator", val = operator} end

--INCLUDE
lincludes = {}
linclude = (lpeg.P"include" * sepNoNL * lstring * ws)/
  function(include) table.insert(lincludes, include.val) end

--FOR LOOP HEADERS
lfornorm = (
  "for" * ws * 
  lvar * ws *
  lpeg.P"from" * ws *
  lnumval * ws *
  lpeg.P"to" * ws * 
  lnumval * ws *
  ((lpeg.P"by" * ws * lnumval)^-1))/
    function(var, first, last, step) return {type = "fornormal", var = var.val, first = first, last = last, step = (step or {type = "numberconst", val = 1})} end

lforen = (
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
