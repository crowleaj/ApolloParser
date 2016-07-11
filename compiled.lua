local x=5
local y=function(foo,bar)
return 45
end
local p=function()
local x=function(me)

return y
end
return x
end
local tryit={function(x)
return {function()
return 4
end}
end}
print(hi)
local nums={{5},function()
local x=2
print("WORKING!!!")
end,7,8,9,10}

for i=18,25,2 do
print(i)
end

Entity={
__initfunction = function(self,foo)
this = {x=0
,y=0
,}
this.foo=foo
setmetatable(this, self)
return this
end
,move=function(self,x,y)
self.x=x
self.y=y
end}
Entity.__index=Entity
local e=Entity:__initfunction(8)
print(e.foo)