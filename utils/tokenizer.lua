
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
