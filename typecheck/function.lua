--Created by Alex Crowley
--On November 3, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms

--[[
    Runs a validation check on function parameters to make sure
    variable names are not duplicated and types are valid
    Returns:
        Error code, 0 if successful
--]]
function checkFunctionParameters(params, scope)
    for i, current in ipairs(params) do
        --TODO: check if type is valid
        for j=i+1,#params,1 do
            if current.name == params[j].name then
                print("ERROR: variable name " .. current.name .. " already defined in function parameters")
                return 1
            end
        end
    end
    return 0
end
