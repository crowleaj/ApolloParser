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

local lkeywords = (lpeg.P"this" + "if" + "or" + "else" + "switch" + "case" + "default" + "for" + "in" + "class" + "cclass" + "var" + "gvar") * sep

local lvarnorm = ((("_" + lpeg.R("az", "AZ")) * (("_" + lpeg.R("az", "AZ", "09"))^0))-lkeywords)/
  function(var) return {type = "variable", val = var} end

local lvarclass = lpeg.P"this->" * (lvarnorm/
  function(var) var.type = "classvariable" return var end)

local lvar = lvarclass + lvarnorm

local lval = lconst + lvar

local lnumval = lnum + lvar

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

local ltypedec = (lvarnorm * sepNoNL * lvarnorm * ws)/
  function(type, var) return {type = "typedec", name = type.val, val = var.val} end

local linclude = (lpeg.P"include" * sepNoNL * lstring * ws)/
  function(include) table.insert(includes, include.val) end
--TODO: fix tablelookup grammar to reject all grammars that don't end in function call or catch error in parser
local cfg = lpeg.P{
  "S",

  S = (lcomment + linclude + lpeg.V"lif" + lpeg.V"lswitch" + lpeg.V"lclassinit" + (lpeg.V"lfunccall" * ws) + lpeg.V"lassignment" + 
  lpeg.V"ltablelookup" + lpeg.V"lcclass" + lpeg.V"lclass" + lpeg.V"ldecl" + lpeg.V"lforloop")^1, 

  lassignment = 
    (((lpeg.V"lclassreference" + lpeg.V"ltablelookup" + lvar) * ws *
      ("=" * ws * (lpeg.V"lfunc" + lpeg.V"ltable" + lpeg.V"larith")))/
        function(var, val) return {type = "assignment", var = var, val = val} end
      ) *ws,

  ldecl = ((llocal + lglobal) * ws * (lpeg.V"lassignment" + (lvarnorm * ws)))/
    function(scope, assignment) assignment.type = "declaration" assignment.scope = scope return assignment end,

  lfunccall = ( lvar * ((lpeg.V"lfunccallparams")^1) * ws)/
    function(func, ...) return {type = "functioncall", name = func, args = {...}} end,
  
  lfunc = 
    (lfuncvars  * ws * 
    "{" * ws *  
    ((lpeg.V"S" * ws)^0) * 
    (lpeg.V"lreturnstatement"^-1) * ws *
    lpeg.P"}" * ws)/ function(vars, ...) return {type="function", vars = vars, val = {...}}   end,
  
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
  
lbody = (
  "{" * ws *  
  ((lpeg.V"S" * ws)^0) * ws * 
  lpeg.P"}" * ws),
  
lif = 
  ((("if" * ws * lpeg.V"larith" * ws * lpeg.V"lbody")/ function(condition, ...) return {type = "if", cond = condition, val = {...}} end) *
  (((lpeg.P"or" * ws * lpeg.V"larith" * ws * lpeg.V"lbody")/ function(condition, ...) return {type = "elseif", cond = condition, val = {...}} end)^0) *
  (((lpeg.P"else" * ws * lpeg.V"lbody")/ function(...) return {type = "else", val ={...}} end)^-1))/
    function(...) return {type = "ifblock", val = {...}} end,
  
  ltablebrackets = ("[" * (lpeg.V"lfunccall" + lpeg.V"ltablelookup" + lval) * "]")/
      function(val) return {type="brackets", val=val} end,

  ltablebody = (lpeg.V"lclassfunction" + lpeg.V"lcclassreference" + ldotref + lpeg.V"ltablebrackets" + lpeg.V"lfunccallparams") * (lpeg.V"ltablebody"^-1) ,

  ltablelookup = (lvar * lpeg.V"ltablebody" * ws)/
      function(name, ...) return {type = "tablelookup", name = name, val = {...}} end,

  lclass = ("class" * ws * lvar * ws * "{" * ws *
  (((lpeg.V"lassignment" + lpeg.V"lclassmethod" + ltypedec + lvar) * ws * (lpeg.P","^-1) * ws)^0) *
  --(((lpeg.V"lassignment" + lpeg.V"lclassmethod" + ltypedec + lvar) * ((ws * (lpeg.P"," + "\n") * ws * (lpeg.V"lassignment" + lpeg.V"lclassmethod" + ltypedec + lvar))^0))^-1) *
  ws * "}" * ws)/
    function(name, ...) classes[name.val] = {...}  return {type = "class", name = name.val} end,

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

  lcclass = ("cclass" * ws * lvar * ws * "{" * ws *
    (((lpeg.V"lfunccall" + lvar) * ws * (lpeg.P","^-1) * ws)^0) *
    ws * "}" * ws)/
      function(name, ...) return {type = "cclass", name = name.val, val = {...}} end,

  lswitch = ("switch(" * ws * lpeg.V"larith" * ws * ")" * ws * "{" *
    ws * ((("case" * ws * lpeg.V"larith" * ws * (lpeg.V"S"^0))/function(case, ...) return {type = "case", cond = case, val = {...}} end)^0) * 
    ((("default" * ws * (lpeg.V"S"^0))/ function(...) return {type = "default", val = {...}} end)^-1) * ws * "}" * ws)/
      function(cond, ...) return {type = "switch", cond = cond, val = {...}} end,

  lrhs = (lpeg.V"lclassreference" + lpeg.V"ltablelookup" + lpeg.V"lfunccall" + lval),
}

--http://stackoverflow.com/questions/1410862/concatenation-of-tables-in-lua
function appendTable(t1,t2)
  local s1 = #t1
  for i=1,#t2 do
      t1[s1+1] = t2[i]
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