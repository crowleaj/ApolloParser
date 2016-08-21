--Created by Alex Crowley
--On August 21, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms

function quicktype(types) 
    local type = types[#types].val types[#types] = nil
    local t = {type = "quicktypes"}
    for _,v in ipairs(types) do 
    v.type = type
    table.insert(t, {name = v.val, ctype = type})
    end
    return t 
end

function functionparams(params) 
    params = params or {} 
    local t = {}
    for _, v in ipairs(params) do
    if v.type == "quicktypes" then
        appendTable(t, v)
    else
        table.insert(t, v)
    end
    end
    return t
end

function noreturnhandle(name, params, returns, body) 
    if body == nil then
    body = returns
    returns = {}
    end
return {type = "function", name = name.val, params = params, returns = returns, body = body} end