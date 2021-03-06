--Created by Alex Crowley
--On July 11, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms

function paramName(param)
  return param.name
end

function annotateMethod(classes, classvars, method)
  --print(inspect(classvars))
  --print(inspect(classvars))
  for _, line in pairs(method.body) do
    local type = line.type
    if type == "assignment" then
      if (contains(method.params, line.name, paramName) == false) and contains(classvars, line.name) then
        line.annotation = "self"
      end
      --print(inspect(line))
    end
  end
end

function annotateSingleInstanceVariables(vars, funcvars, inst, ann)
  local type = inst.type
  if type == "variable" then
    if contains(vars, funcvars, inst.val) then
      inst.val = ann .. "." .. inst.val
    end
  elseif type == "classvariable" then
    inst.val = ann .. "." .. inst.val
  elseif type == "function" then
    local copy = deepcopy(funcvars)
    for _,v in ipairs(inst.vars) do
      table.insert(copy.vars, inst.val)
    end
    annotateInstanceVariables(vars, funcvars, inst.vars, ann)
    annotateInstanceVariables(vars, copy, inst.val, ann)
  elseif type == "assignment" then
    annotateSingleInstanceVariables(vars, funcvars, inst.var, ann)
    annotateSingleInstanceVariables(vars, funcvars, inst.val, ann)
  elseif type == "arithmetic" or type == "params" or type == "else" then
    annotateInstanceVariables(vars, funcvars, inst.val, ann)
  elseif type == "parentheses" or type == "brackets" then
    annotateSingleInstanceVariables(vars, funcvars, inst.val, ann)
  elseif type == "tablelookup" then
    annotateSingleInstanceVariables(vars, funcvars, inst.name, ann)
    annotateInstanceVariables(vars, funcvars, inst.val, ann)
  elseif type == "functioncall" then
    annotateInstanceVariables(vars, funcvars, inst.args, ann)
    if contains(vars, funcvars, inst.name.val) then
      inst.name.val = ann .. ":" .. inst.name.val
    end
  elseif type == "ifblock" then
    annotateInstanceVariables(vars, funcvars, inst.val, ann)
  elseif type == "switch" or type == "case" or type == "if" or type == "elseif" then
    annotateSingleInstanceVariables(vars, funcvars, inst.cond, ann)
    annotateInstanceVariables(vars, funcvars, inst.val, ann)
  elseif type == "forloop" then
    annotateSingleInstanceVariables(vars, funcvars, inst.iter, ann)
    type = inst.iter.type
    local copy = deepcopy(funcvars)
    if type == "fornormal" then
      annotateSingleInstanceVariables(vars, funcvars, inst.iter.first, ann)
      annotateSingleInstanceVariables(vars, funcvars, inst.iter.last, ann)
      annotateSingleInstanceVariables(vars, funcvars, inst.iter.step, ann)
      table.insert(copy.vars, inst.iter.var)
    elseif type == "forenhanced" then
      annotateSingleInstanceVariables(vars, funcvars, inst.iter.var, ann)
      table.insert(copy.vars, inst.iter.vals.k)
      table.insert(copy.vars, inst.iter.vals.v)
    end
    annotateInstanceVariables(vars, copy, inst.val, ann)
  else
    --print(type)
  end
end

function annotateInstanceVariables(vars, funcvars, code, ann)
  for _,inst in pairs(code) do
    annotateSingleInstanceVariables(vars, funcvars, inst, ann)
  end
end