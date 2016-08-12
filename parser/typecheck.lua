
local primitives = {bool = 1, char = 2, short = 3, int = 4, long = 5, float = 6, float64 = 7, string = 1}

local function isPrimitive(type)
    return (primitives[type] >= 1)
end

local function precisionLoss(varname, vartype, valtype)
    if primitives[vartype] < primitives[valtype] then
        print("WARNING: Potential loss of precision converting assignment of " .. varname .. " from " .. valtype .. " to " .. vartype)
    end
end


function checkFunction(body, returns, scope)
    for _, line in pairs(body) do
        local type = line.type
        if type == "declassignment" then
            if line.ctype.type == "variable" then
                type = line.ctype.val
                if isPrimitive(type) then
                    print(inspect(line))
                    if type == "string" then
                            
                    else
                        if line.val.type == "constant" then
                            precisionLoss(line.name, type, line.val.ctype)
                        end
                    end
                end
            
            end
        end
    end
    return 0
end