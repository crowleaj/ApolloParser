require "lpeg"

local retval = function(val) return val end
local retsp = retval(" ")
local noret = retval("")
local newln = retval("\n")

local ws = (lpeg.P(" ") +"\n")^0
local wsCs = (ws/noret)
local wsOne =  (ws/retsp)
local wsNl = (ws/"\n")
local lnum = lpeg.C(((lpeg.R("09")^1) * (("." * (lpeg.R("09")^0)) + "")) + ("." * (lpeg.R("09")^1)))
local lstring = lpeg.C(("'" * ((lpeg.P(1)-"'")^0) * "'") + ('"' * ((lpeg.P(1)-'"')^0) * '"'))

local lconst = (lnum + lstring)
local lvar = lpeg.C(("_" + lpeg.R("az", "AZ")) * ("_" + lpeg.R("az", "AZ", "09"))^0)
local lval = lconst+lvar
local lnumval = lnum+lvar

local llocal = ("var" * ws) / retval("local ")
local lglobal = ("gvar" * ws) / noret

local lcomment = lpeg.Cs("--" * ((lpeg.P(1) - "\n")^0) * "\n" * wsCs)

local lfuncvars = lpeg.Cs( 
  "(" * wsCs * 
  (
    (((lval * wsCs * ","* wsCs)^0) * lval) 
    + wsCs
  ) * wsCs * 
  ")")
    
--local lfunccall = (lvar * lfuncvars)/function(func,args) return func .. args end

local lfornorm = lpeg.Cs(
  "for" * wsOne * 
  lvar * wsCs *
  (lpeg.P"from"/"=") * wsCs *
  lnumval * wsCs *
  (lpeg.P"to"/",") * wsCs * 
  lnumval * wsCs *
  ((lpeg.P"by"/"," * wsCs * lnumval)^-1))

local lforen = lpeg.Cs(
  "for" * wsOne * 
  (
    (lvar * wsCs * "," * wsCs * lvar)
    +((lpeg.P"i"+"k")/
      function(index) return index .. "," .. "_" end)
    +((lvar-(lpeg.P"i"+"k"))/
      function(var) return "_" .. "," .. var end)
  ) 
  * wsOne * "in " * wsOne * 
  (
    (lvar * ws *
      (
        lpeg.P"pairs"
        + (lpeg.P"array"/"ipairs")
    ))/
      function(var,iter) return iter .."(" .. var..")" end))
  
local arithOp = lpeg.C(lpeg.S("*/+-"))
local lcompare = lpeg.C(lpeg.S("<>") + "<=" + ">=" + "==")

local opOverload = lpeg.P(
  (lvar * ws * arithOp * "=" * ws * lvar)/
    function (left, op, right)
      return "" .. left .. "=" .. left .. op .. right
    end
  )

local cfg = lpeg.P{
  "S",
  S = (lcomment + lpeg.V"lassignment" + lpeg.V"ldecl" + lpeg.V"lif" + lpeg.V"lforloop" + (lpeg.V"lfunccall" * wsNl) + lpeg.V"ltablelookup")^1,
  --((lpeg.P(" ") +"\n")^1)/"\n",
  
  lassignment = 
    ((lvar * wsCs *
    (
      ("=" * wsCs * (lpeg.V"ltablelookup" + lpeg.V"larith" + lval + lpeg.V"ltable")) 
      + ("=" * wsCs * lpeg.V"lfunc")))
  + ((lvar/function(...) return ... .. "=" end) * wsCs * lpeg.V"lfunc")) *wsNl,
    
  ldecl = lpeg.Cs(((llocal + lglobal) * wsOne * lpeg.V"lassignment")),

  lfunccall = lpeg.Cs((lvar * (lpeg.V"ltablebrackets" + lpeg.V"lfunccallparams") * ((lpeg.V"lfunccallparams")^0) * wsCs)),
  
  lfunc = 
    (lfuncvars/
      function(vars) return "function".. vars end) * wsNl * 
    (lpeg.P"{"/noret) * wsCs *  
    ((((lpeg.V"lfunccall"/
            function(...) return ... .. "\n"end) 
      + lpeg.V"S") * wsCs)^0) * 
    ((lpeg.V"lreturnstatement"^-1)) * wsCs *
    (lpeg.P"}"/noret) *
    (ws/"end"),
  
  lfunccallparams = 
    "(" * wsCs * 
    ((
      (((lpeg.V"lfunccall" + lpeg.V"larith" + lval) * wsCs * "," * wsCs)^0) *
      (lpeg.V"lfunccall" + lpeg.V"larith" + lval) * wsCs) 
    + wsCs) *
    ")",
  
  lreturnstatement = "return" * wsOne * (lpeg.V"ltablelookup" + lpeg.V"ltable" + lpeg.V"lfunc" + lpeg.V"larith" + lval) * wsNl,
  
  larith = 
    (
      (lpeg.V"lfunccall" + lnumval) * 
      (
        ((wsCs * arithOp * wsCs * (lpeg.V"lfunccall" + lnumval))^1)
        + (wsCs * arithOp * wsCs *lpeg.V"larithbal")))
    + lpeg.V"larithbal",

  larithbal = wsCs * "(" * wsCs * (lpeg.V"larith" + lpeg.V"larithbal") * wsCs * ")",
  
  ltable = lpeg.Cs(
    (lpeg.P"["/"{") * wsCs * 
    (((((lpeg.V"ltable" + lpeg.V"lfunccall" + lval + lpeg.V"lfunc") * wsCs* ",")^0) * (lpeg.V"ltable" + lpeg.V"lfunccall" + lval + lpeg.V"lfunc"))+"")  * wsCs *
    (lpeg.P"]"/"}")),

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
      (lpeg.P"else"/"else\n") * (lpeg.V"lbody"/
        function(...) return ... .. "end\n" end)
  )
    +(lpeg.P"else"/"else\n") * (lpeg.V"lbody"/
        function(...) return ... .. "end\n" end)
    +(lpeg.V"lbody"/
      function(...) return "then\n" .. ... .. "end" end)
    ),
  
ltablebrackets = ("[" * lval * "]" * ((lpeg.V"ltablebrackets" + (lpeg.V"lfunccallparams" * lpeg.V"ltablebrackets"))^-1)),

ltablelookup = lvar*lpeg.V"ltablebrackets",
}
function runfile(file,output)
  local f = io.open(file, "rb")
  local script = f:read("*all")
  f:close()
  run(script,output)
end

function run(script,output)
  local p = lpeg.Cs((cfg)^0):match(script)
  if output == true then
      print(p)
  end
  local chunk, err = assert(loadstring(p))
  if chunk == nil then
    print(err)
  else
    chunk()
    io.write "\n"
  end
end