require "parser"

runfile("test.ns",true)

--local m = Entity:__initfunction("Alice")
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

var nums = [[5],(){var x=2 print("WORKING!!!")},7,8,9,10]

--for index,num in nums array {
--  print("Testing for loop!")
--}
for i from 18 to 25 by 2 {
  print(i)
}
print(5,4,6,7)
print(print(5,4,p(6)(10)),6,7)
var tryit = [(x){return [(){ return 4}]}]
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

class Entity { 
	
		x = 0, y = 0
		foo
		
		Entity(name){
			print(name)
		}
		
		
}]]