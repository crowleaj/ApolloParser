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
