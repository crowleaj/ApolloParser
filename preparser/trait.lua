--Created by Alex Crowley
--On August 7, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms

  require "parser/queue"
  require "preparser/common"
  
--TODO: Consider traits after classes are working properly

--[[
  Checks the hierarchy of the traits to ensure
  descending traits agree in class specification (get more specific not less)
  and that there are no inconsistencies where for example t1 is a direct parent of
  t2 and both t1 and t2 are direct parents of t3.
]]
function verifyTraitHierarchy(traits, class, toplevel)

end


function removelistindices(list, indices)
  if #indices > 0 then
    for i=#indices,1 do
      table.remove(list, indices[i])
    end
  end
end

local function establishIsa(traits, toplevel)
  local queued = {}
  local queue = Queue.new()
  for _, v in pairs(toplevel) do
    queued[v.name] = 1
    Queue.enqueue(queue, v)
  end
  while Queue.empty(queue) == false do
    local trait = Queue.dequeue(queue)
    local toremove = {}
    for i, parent in pairs(trait.traits) do
      if parent ~= "Any" then
        for _, compareTrait in pairs(trait.traits) do
          if compareTrait ~= parent then
            if contains(traits[compareTrait].isa, parent) == true then
              table.insert(toremove, i)
            end
          end
        end
      elseif #trait.traits > 1 then
        table.insert(toremove, i)
      end
    end
    removelistindices(trait.traits, toremove)
    local isa = {}
    for _, parent in pairs(trait.traits) do 
      if parent == "Any" then
        table.insert(isa, parent)
      else
        for _, is in pairs(traits[parent].isa) do
          if contains(isa, is) == false then
            table.insert(isa, is)
          end
        end
      end
    end
    table.insert(isa, trait.name)
    trait.isa = isa
    for _, child in pairs(trait.children) do
      if queued[child] == nil then
        queued[child] = 1
        Queue.enqueue(queue, traits[child])
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
        table.insert(trait.traits, "Any")
        table.insert(toplevel, trait)
      elseif (#trait.traits == 1 and trait.traits[1] == "Any") then
        table.insert(toplevel, trait)
      else
        for _, t in pairs(trait.traits) do
          t = traits[t]
          table.insert(t.children, name)
        end
      end
  end
  establishIsa(traits, toplevel)
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
    preParseBody(trait)
  end
  linearizeTraits(traits)
end