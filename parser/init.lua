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
--require "parser/ifblock"
--require "parser/for"
--require "parser/switch"
--require "parser/class"

--require "classann"

require "preparser"

require "utils"
require "typecheck"

require "parser/newparser"

--Each file will have functions, variables and body, last file will have main
function parseFiles(tree)
  --local global, files, main = preParse(tree)
  --print(inspect(global))
  local nTree = {"do\nlocal __bit = require(\"bit\")"}
  local scope = {}

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
    io.write "\n"
    print("Output:")
    chunk()
    io.write "\n"
  end
end
