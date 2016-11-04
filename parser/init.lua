--Created by Alex Crowley
--On July 8, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms

require "lexer"

require "parser/arithmetic"
require "parser/value"
require "parser/assignment"
require "parser/function"
require "parser/ifblock"
require "parser/for"
require "parser/switch"
--require "parser/class"

--require "classann"

require "preparser"

require "utils"
require "typecheck"

require "parser/newparser"
--[[
function parseLine(line, scope)
  local nTree = {}
  local type = line.type
  if type == "declaration" or type == "classinit" then
    table.insert(nTree, parseAssignment(line, scope))
  elseif type == "functioncall" then
    table.insert(nTree, parseValue(line, scope))
    table.insert(nTree, "\n")
  elseif type == "tablelookup" then
    table.insert(nTree,parseValue(line, scope))
    table.insert(nTree, "\n")
  elseif type == "forloop" then
    table.insert(nTree, parseFor(line))
  elseif type == "function" then
    table.insert(nTree, parseFunction(line))
  elseif type == "assignment" or type == "declassignment" then
    table.insert(nTree, parseDeclaration(line))
  elseif type == "ifblock" then
    table.insert(nTree, parseIfBlock(line))
  elseif type == "switch" then

    table.insert(nTree, parseSwitch(line))
  elseif type == "comment" then
    --print(line.val)
  else
    print("unrecognized instruction: " .. inspect(line))
  end
  return table.concat(nTree)
end
--]]
--Each file will have functions, variables and body, last file will have main


function parseFiles(tree)
  --local global, files, main = preParse(tree)
  --print(inspect(global))
  local nTree = {"do\nlocal __bit = require(\"bit\")"}
  local scope = {}
--[[
  table.insert(nTree, parseClasses(global.classes, global.classtoplevel))

  for _,file in ipairs(files) do
    for _, func in pairs(file.functions) do
      table.insert(nTree, parseFunction(func))
    end
  end
  local result = checkFunction(main.body, main.returns, {global = global, file = files[#files], params = main.params})
  if result ~= 0 then
    return ""
  end
  table.insert(nTree, parseFunction(main))
  table.insert(nTree, "main()")
  --]]
  local scope = {global = {variables = {}}}
  for _, file in ipairs(tree) do
    local err, parsed = parseFile(file, scope)
      --print(inspect(scope))
    if err > 0 then
      return err
    end
    table.insert(nTree, parsed)
  end
  table.insert(nTree, "end")
  return 0, table.concat(nTree, "\n")
end

function loadfile(file)
  local f = io.open(file .. ".as", "rb")
  local script = f:read("*all")
  f:close()
  return script
end

function runfile(file,output)
  run(loadfile(file),output)
end

function run(script,output)
  local p, classes = lex(script)
  --preparseClasses(classes)
  --print(inspect(classes))
  --print(inspect(p))
  local err
  err, p = parseFiles(p)
  if err > 0 then
    print("Parser terminated unexpectedly")
    return
  end
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
