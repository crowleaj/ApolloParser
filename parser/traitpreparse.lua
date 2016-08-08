--Created by Alex Crowley
--On August 7, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms

--[[
  Responsible for establishing a hierarchy for traits
  Assigns direct descendents to each trait
  Returns top level of traits
]]
function linearizeTraits(traits)
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
  Checks the hierarchy of the traits to ensure
  descending traits agree in class specification (get more specific not less)
  and that there are no inconsistencies where for example t1 is a direct parent of
  t2 and both t1 and t2 are direct parents of t3
]]
function verifyTraitHierarchy(traits, toplevel)

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
end