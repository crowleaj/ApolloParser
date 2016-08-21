--Created by Alex Crowley
--On July 8, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms

package.cpath = package.cpath .. ";./lpeg/?.so"
require "lpeg"
require "utils"
require "lexer/regexps"

local cfg = require "lexer/cfg"

local function lexdeps(script, parsed)
  parsed[script] = 1
  local tree = {lpeg.Ct(ws * (cfg)^0):match(script)}
  while #lincludes ~= 0 do
    local incl = lincludes
    lincludes = {}
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