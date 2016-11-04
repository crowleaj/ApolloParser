--Created by Alex Crowley
--On November 2, 2016
--Copyright (c) 2016, TBD
--Licensed under the MIT license
--See LICENSE file for terms

--[[
  Used to iterate through tokens in a syntax tree.  Primarily used by precedent parser.
--]]
Tokenizer = {}

--[[
  Creates new Tokenizer object.
--]]
function Tokenizer.new(tokens)
  return {vals = tokens, current = 1}
end

--[[
  Gets the current object the iterator is on.
--]]
function Tokenizer.current(tokens)
  return tokens.vals[tokens.current]
end

--[[
  Advances the tokenizer to the next token.
--]]
function Tokenizer.next(tokens)
  tokens.current = tokens.current + 1
end
