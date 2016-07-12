require "parser"

runfile("test.ns",false)


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
if q < 5 {
  print(q)
}
or q < 10 {
  print(q)
}
else {
  print("else statement")
}
]]