--Created by Alex Crowley
--On November 3, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms


--[[
  Contains functions pertaining to the use of scope when type checking.
--]]


--[[
  Relsoves the desired variable to the inner most scope.
  Returns: Type of variable, or nil if not found
--]]
function resolveVariable(varname, scope)
  local func = scope.func
  local count = 1
  while func ~= nil do
    if func.variables[varname] ~= nil then
      return func.variables[varname]--count
    end
    func = func.func
    count = count + 1
  end
  if scope.file.variables[varname] ~= nil then
    return scope.file.variables[varname]--count + 1
  elseif scope.global.variables[varname] ~= nil then
    return scope.global.variables[varname]--count + 2
  else
    return nil
  end

end

--[[
    Gets the return types from the innermost function.
    Needed because func is treated as a new "scope" in the sense
    that variables undefined in current scope are free to be defined.
    Parsing a function creates a scope with function parameters  and returns then defines a "clean" func scope
    Returns:
        Return types of innermost function
--]]
function getReturns(scope)
    local func = scope.func
    while func.returns == nil do
        func = func.func
    end
    return func.returns
end
