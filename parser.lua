require "lpeg"
local inspect = require "inspect"

local retval = function(val) return val end
local retsp = retval(" ")
local noret = retval("")
local newln = retval("\n")

local ws = ((lpeg.P(" ") + "\n"+"\t")^0)
local wsCs = (ws/noret)
local wsOne =  (ws/retsp)
local wsNl = (ws/"\n")
local lnum = ((((lpeg.R("09")^1) * (("." * (lpeg.R("09")^0)) + "")) + ("." * (lpeg.R("09")^1)))/
  function (num) return {type = "numberconst",val = num} end)
local lstring = ((("'" * ((lpeg.P(1)-"'")^0) * "'") + ('"' * ((lpeg.P(1)-'"')^0) * '"'))/
  function  (string) return {type = "stringconst", val = string}  end
)

local lconst = (lnum + lstring)
local lvarnorm = ((("_" + lpeg.R("az", "AZ")) * (("_" + lpeg.R("az", "AZ", "09"))^0))/
  function(var) return {type = "variable", val = var} end)
local lvarclass = ((lpeg.P"this:" * ("_" + lpeg.R("az", "AZ")) * (("_" + lpeg.R("az", "AZ", "09"))^0))/
  function(var) return {type = "classvariable", val = var} end)
local lvar = lvarclass + lvarnorm
local lval = lconst+lvar
local lnumval = lnum+lvar

local llocal = ("var" * ws)/retval("local")
local lglobal = ("gvar" * ws)/retval("global")

local lcomment = (("--" * (((lpeg.P(1) - "\n")^0)/retval) * "\n" * wsCs)/
  function(...) return {type = "comment", val = ...} end)

local lfuncvars =  
  ("(" * ws * 
  (
    (((lvar * ws * ","* ws)^0) * lvar) 
    + ws
  ) * ws * 
  ")")/
    function(...) if ... == "()" then return {} else return {...} end end

local lfornorm = (
  "for" * ws * 
  lvar * ws *
  lpeg.P"from" * ws *
  lnumval * ws *
  lpeg.P"to" * ws * 
  lnumval * ws *
  ((lpeg.P"by" * ws * lnumval)^-1))/
    function (first,last,step) return {type = "fornormal", first = first, last = last, step = (step or {type = "numberconst", val = 1})} end

local lforen = (
  "for" * ws * 
  (
    (lvar * wsCs * "," * wsCs * lvar)
    +((lpeg.P"i"+"k")/
      function(index) return index .. "," .. "_" end)
    +((lvar-(lpeg.P"i"+"k"))/
      function(var) return "_" .. "," .. var end)
  ) 
  * ws * "in " * ws * 
  (
    (lvar * ws *
      (
        lpeg.P"pairs"
        + (lpeg.P"array"/"ipairs")
    ))/
      function(var,iter) return iter .."(" .. var..")" end))
  
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
  S = ( lcomment + lpeg.V"lclass" + lpeg.V"lassignment" + lpeg.V"ldecl" + lpeg.V"lif" + lpeg.V"lforloop" + lpeg.V"ltablelookup")^1,--+ (lpeg.V"lfunccall" * ws) 
  --((lpeg.P(" ") +"\n")^1)/"\n",
  
  lassignment = 
    ((lvar * ws *
      ("=" * ws * (lpeg.V"ltablelookup" + lpeg.V"larith" + lval + lpeg.V"ltable" + lpeg.V"lfunc")))/
        function(var,val) return {type = "assignment", var = var, val = val} end
      ) *ws,

  ldecl = ((llocal + lglobal) * ws * (lpeg.V"lassignment" + (lvarnorm * ws)))/
    function(scope,assignment) 
     if type(assignment) == "string" then return {type = "declaration", var = var}
     else assignment.type = "declaration" assignment.scope = scope return assignment end end,

  lfunccall = lpeg.Cs((lvar * (lpeg.V"ltablebrackets" + lpeg.V"lfunccallparams") * ((lpeg.V"lfunccallparams")^0) * wsCs)),
  
  lfunc = 
    (lfuncvars  * ws * 
    "{" * ws *  
    ((lpeg.V"S" * ws)^0) * 
    (lpeg.V"lreturnstatement"^-1) * ws *
    lpeg.P"}" * ws)/ function(vars, ... ) return {type="function", vars = vars, val = {...}}   end,
  
  lfunccallparams = 
    "(" * wsCs * 
    ((
      (((lpeg.V"lfunccall" + lpeg.V"larith" + lval) * wsCs * "," * wsCs)^0) *
      (lpeg.V"lfunccall" + lpeg.V"larith" + lval) * wsCs) 
    + wsCs) *
    ")",
  
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

  larithbal = (ws * "(" * ws * (lpeg.V"larith" + lpeg.V"larithbal") * ws * ")" * ws)/
    function(val) return {type = "parentheses", val = val} end,
  
  ltable = (
    "[" * ws * 
    (((((lpeg.V"ltable" + lpeg.V"lfunccall" + lval + lpeg.V"lfunc") * ws* ",")^0) * (lpeg.V"ltable" + lpeg.V"lfunccall" + lval + lpeg.V"lfunc"))^-1)  * ws *
    "]")/ 
      function(...) return {type = "table", val={...}} end,

lforloop = (lforen + lfornorm) * wsOne * lpeg.V"lforbody" * wsNl,

lforbody =   
  (lpeg.P"{"/" do\n") * wsCs *  
  ((lpeg.V"S" * wsCs)^0) * wsCs * 
  (lpeg.P"}"/noret) * 
  (ws/"end"),
  
lbody = lpeg.Cs(
  (lpeg.P"{"/"") * wsCs *  
  ((lpeg.V"S" * wsCs)^0) * wsCs * 
  (lpeg.P"}"/noret) * wsCs),
  
lif = 
  "if" * wsOne * (lpeg.V"lfunccall" + lval) * wsCs * lcompare * ws * (lpeg.V"lfunccall" + lval) * wsOne * 
  (
    ((lpeg.V"lbody"/
        function(...) return "then\n" .. ... end)  * 
       (((lpeg.P"or"/"elseif") * wsOne * (lpeg.V"lfunccall" + lval) * wsCs * lcompare * ws * (lpeg.V"lfunccall" + lval) * wsOne * 
      (lpeg.V"lbody"/
        function(...) return "then\n" .. ... end))^0) *
      (lpeg.P"else"/"else\n") * wsOne * (lpeg.V"lbody"/
        function(...) return ... .. "end\n" end)
  )
    +(lpeg.P"else"/"else\n") * wsOne * (lpeg.V"lbody"/
        function(...) return ... .. "end\n" end)
    +(lpeg.V"lbody"/
      function(...) return "then\n" .. ... .. "end" end)
    ),
  
ltablebrackets = ("[" * lval * "]" * ((lpeg.V"ltablebrackets" + (lpeg.V"lfunccallparams" * lpeg.V"ltablebrackets"))^-1)),

ltablelookup = lvar * (lpeg.V"ltablebrackets" + ("." * lvar)),

lclass = lpeg.Cs(("class" * ws * lvar * ws * "{" * ws * lpeg.Ct(( (( lpeg.Ct(lvar * lpeg.V"lfunc")) + lpeg.Ct(lpeg.Cs(lpeg.V"lassignment")/
function ( ... ) return {...} end) + lvar)  * ws * (lpeg.P(",")^-1) * ws)^0) * ws * "}" * ws)/
function (cname,var) 
  local assignments = {}
  local constructor = nil
  local functions = {}
  for _,v in pairs(var) do 
    if type(v) == "table" then
      if #v == 1 then 
        table.insert(assignments,table.concat(v[1]))
      elseif v[1] == cname then
        constructor = v
      else
        table.insert(functions,table.concat(v))
      end
    end
  end 
  if constructor ~= nil then
    constructor[1] =  "function " .. cname .. ":__init"
    local fcn = {}
    for k,v in ipairs(constructor) do
      table.insert(fcn,v)
      if k == 2 then
        table.insert(fcn,"\nlocal this ={")
        for _,decl in ipairs(assignments) do
          table.insert(fcn,decl .. ",")
        end
        table.insert(fcn,"} setmetatable(this, self)")
      end
    end
    fcn[#fcn] = "return this\nend\n"
    return cname .."={}\n" .. table.concat(fcn) .. cname .. ".__index=" .. cname .. "\n" 
  else
    return cname .. "={ }\n" .. cname .. ".__index=" .. cname .. "\n" 
  end
end),
}
function runfile(file,output)
  local f = io.open(file, "rb")
  local script = f:read("*all")
  f:close()
  run(script,output)
end

function run(script,output)
  local p = lpeg.Ct((cfg)^0):match(script)
  for _, inst in ipairs(p) do
    local type = inst.type
    print(inspect(inst))
    if type == "comment" then
    elseif type == "assignment" then
      --print("assignmnt: " .. "var: " .. inspect(inst.var) .. "val: " .. inspect(inst.val))
    end
  end
  if output == true then
      --print(p)
  end
  --[[local chunk, err = assert(loadstring(p))
  if chunk == nil then
    print(err)
  else
    chunk()
    io.write "\n"
  end--]]
end