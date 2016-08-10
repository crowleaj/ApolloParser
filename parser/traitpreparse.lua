--Created by Alex Crowley
--On August 7, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms
  require "parser/queue"
--[[
  Checks the hierarchy of the traits to ensure
  descending traits agree in class specification (get more specific not less)
  and that there are no inconsistencies where for example t1 is a direct parent of
  t2 and both t1 and t2 are direct parents of t3.
]]
function verifyTraitHierarchy(traits, class, toplevel)

end

function contains(list, item)
  for _, v in pairs(list) do
    if item == v then
      return true
    end
  end
  return false
end

local function establishIsa(traits, toplevel)
  local queued = {}
  local queue = Queue.new()
  for name, v in pairs(toplevel) do
    queued[name] = 1
    Queue.enqueue(queue, {v, {"Any"}})
  end
  while Queue.isempty(queue) == false do
    local item = Queue.dequeue(queue)
    local trait = item[1]
    local isa = item[2]
    for _, t in pairs(trait.traits) do
      
    end
    table.insert(isa, trait.name)
    for 
  end
  for name, trait in pairs(traits) do  
      if #trait.traits == 0 then
        table.insert(toplevel, trait)
      else
        for _, t in pairs(trait.traits) do
          t = traits[t]
          table.insert(t.children, name)
        end
      end
  end
end

--[[
  Responsible for establishing a hierarchy for traits
  Assigns direct descendents to each trait
  Returns top level of traits
]]
local function linearizeTraits(traits)
  local toplevel = {}
  for name, trait in pairs(traits) do  
      if #trait.traits == 0 then
        table.insert(toplevel, trait)
      else
        for _, t in pairs(trait.traits) do
          t = traits[t]
          table.insert(t.children, name)
        end
      end
  end
  return toplevel
end

--[[
  Organizes trait data from lexer
]]
function preParseTraits(traits)
  for _, trait in pairs(traits) do
    trait.traits = {}
    trait.children = {}
    for _, arg in ipairs(trait.val) do
      local type = arg.type
      if type == "class" then
        trait.class = arg.name
      elseif type == "trait" then
        table.insert(trait.traits, arg.name)
      else
        trait.body = arg
      end
    end
    if trait.class == nil then
        trait.class = "Any"
    end
    trait.val = nil
    trait.type = nil
  end
  linearizeTraits(traits)
end