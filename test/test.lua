require "parser"


runfile("capabilities/03_calls",true)

--[[
A = {
  b = function() B.b() end
}
B = {
  b = function() print "hi" end
}
A.b()
--]]
--runfile("../scripts/controller.ns",false)

--print(m.x)
--[[Entity = {
	__init = function (self,name)
		local this = {x=0,y=0}
		this.name = name
		setmetatable(o,self)
		return o		
	end,
	move = function(self,x,y)
		self.x = x
		self.y = y
	end
}
Entity.__index = Entity
local m = Entity:__init("Alice")
local v = Entity:__init("Bob")
m:move(2,3)
print(m.x)
print(v.name)--



print(5,4,6,7)
print(print(5,4,p(6)(10)),6,7)

print(tryit[1](0)[1]())


var q = 6
]]
