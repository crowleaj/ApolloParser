--Created by Alex Crowley
--On July 11, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms

function contains(pair, nopair, key)
  for _,v in ipairs(pair.vars) do
    if v == key then
      for _,v in ipairs(nopair) do
        if v == key then
          return false
        end
      end
      return true
    end
  end
  for _,v in ipairs(pair.methods) do
  if v.name == key then
    for _,v in ipairs(nopair) do
      if v == key then
        return false
      end
    end
    return true
  end
end
  return false
end

function annotateInstanceVariables(vars,funcvars,code,ann)
  for _,inst in pairs(code) do
    local type = inst.type
    if type == "variable" then
      if contains(vars, funcvars, inst.val) then
        inst.val = ann .. "." .. inst.val
      end
    elseif type == "classvariable" then
      inst.val = ann .. "." .. inst.val
    elseif type == "assignment" then
      if inst.var.type == "classvariable" or contains(vars, funcvars, inst.var.val) then
        inst.var.val = ann .. "." .. inst.var.val
      end
      if inst.val.type == "function" then
        annotateInstanceVariables(vars, funcvars, inst.val.val, ann)
      elseif inst.val.type == "variable" then
        if contains(vars, funcvars, inst.val.val) then
          inst.val.val = ann .. "." .. inst.val.val
        end
      elseif inst.val.type == "classvariable" then
        inst.val.val = ann .. "." .. inst.val.val
      end
    elseif type == "forloop" then
      type = inst.iter.type
      local copy = shallowcopy(funcvars)
      if type == "fornormal" then
        if inst.iter.first.type == "classvariable" or contains(vars, funcvars, inst.iter.first.val) then
          inst.iter.first.val = ann .. "." .. inst.iter.var
        end
        if inst.iter.last.type == "classvariable" or contains(vars, funcvars, inst.iter.last.val) then
          inst.iter.last.val = ann .. "." .. inst.iter.last.val
        end
        if inst.iter.step.type == "classvariable" or contains(vars, funcvars, inst.iter.step.val) then
          inst.iter.step.val = ann .. "." .. inst.iter.step.val
        end
        table.insert(copy,inst.iter.var)
      elseif type == "forenhanced" then
        if inst.iter.var.type == "classvariable" or contains(vars, funcvars, inst.iter.var.val) then
          inst.iter.var.val = ann .. "." .. inst.iter.var.val
        end
        table.insert(copy,inst.iter.vals.k)
        table.insert(copy,inst.iter.vals.v)
      end
      annotateInstanceVariables(vars, copy, inst.val, ann)
    elseif type == "functioncall" then
      annotateInstanceVariables(vars, funcvars, inst.args, ann)
      if contains(vars, funcvars, inst.name.val) then
        inst.name.val = ann .. ":" .. inst.name.val
      end
    elseif type == "params" then
      annotateInstanceVariables(vars, funcvars, inst.val, ann)
    elseif type == "tablelookup" then
      if inst.name.type == "classvariable" or contains(vars, funcvars, inst.name.val) then
          inst.iter.first.val = ann .. "." .. inst.iter.var
      end
      annotateInstanceVariables(vars, funcvars, inst.val, ann)
    else
      print(type)
    end
  end
end