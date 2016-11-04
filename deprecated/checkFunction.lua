function checkFunction(body, returns, scope)
    locals = {}
    for _, line in pairs(body) do
        local type = line.type
        if type == "declassignment" then
            if locals[line.name] ~= nil then
                print("ERROR: variable " .. line.name .. " already defined locally as " .. locals[line.name].ctype.val)
                return 1
            end
            if line.ctype.type == "flat" then
                type = line.ctype.ctype
                if isPrimitive(type) then
                    if type == "string" then
                        if line.val.type == "constant" then
                            if line.val.ctype ~= "string" then
                                print("ERROR: invalid conversion of " .. line.name .. " from string to " .. line.val.ctype)
                                return 1
                            end
                        end
                    else
                        local ctype
                        if line.val.type == "constant" then
                            ctype = line.val.ctype
                        elseif line.val.type == "variable" then
                            ctype = resolveVariable(line.val.val, locals, scope)
                            if ctype == nil then
                                print("ERROR: undefined variable " .. line.val.val .. " in assignment of " .. line.name)
                                return 1
                            elseif ctype.type ~= "flat" then
                                print("ERROR: improper type TODO used")
                                return 1
                            else
                                ctype = ctype.ctype
                            end
                        end
                        if ctype == "string" then
                            print("ERROR: invalid conversion of " .. line.name .. " from ".. type .. " to string")
                            return 1
                        end
                        precisionLoss(line.name, type, ctype)
                    end
                    locals[line.name] = line.ctype
                end
            end

        end
    end
    --print(inspect(locals))
    return 0
end
