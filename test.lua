require "parser"

runfile("test.ns",true)

Entity = {
	__init = function (self,name)
		local o = {x=0,y=0}
		o.name = name
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
print(v.name)