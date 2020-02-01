pico-8 cartridge // http://www.pico-8.com
version 18
--setup
__lua__
function _init()
  title_loop()
end

function title_loop()
  main_menu_init() 
  _update=title_update
  _draw=title_draw
end

function rp_loop()
  _update=rp_update
  _draw=rp_draw
end

function inst_loop()
  _update=inst_update
  _draw=inst_draw
end

ticks={}

function tick(int)
 local t={
  int=int,
  cur=0
 }

 function t:new(o)
  local o=o or {}
  setmetatable(o,self)
  self.__index=self
  return o
 end

 function t:ready()
  if self.cur==0 then return true else return false end
 end

 function t:trigger()
  self.cur=self.int
 end

 function t:update()
  if self.cur>0 then self.cur-=1 end
 end

 new_tick=t:new(nil)
 add(ticks,new_tick)
 return new_tick
end

function update_ticks()
 foreach(ticks,function(obj) obj:update() end)
end

input_tick=tick(15) --half-second input delay

function can_input()
 
end

-->8
--main menu
function menu(init)
 local m=init or {
  --set props
  cur=1,
  choices={},
  x=40,
  y=30,
  spc=10,
  col=7
 }

 function m:new(o)
  local o=o or {}
  setmetatable(o,self)
  self.__index=self
  return o
 end

 function m:add_choice(name,func)
  add(self.choices,{name=name,func=func})
 end

 function m:execute_choice()
  self.choices[self.cur].func()
 end

 function m:cur_update()
  if input_tick:ready() then
   if btn(2) and self.cur>1 then
    self.cur-=1
   elseif btn(3) and self.cur<#self.choices then
    self.cur+=1
   end
   if btn(4) then self:execute_choice() end
  end
 end

 function m:update()
  self:cur_update()
 end

 function m:cur_draw()
  for i=1,#self.choices do
   print(self.choices[i].name,self.x,i*self.spc+self.y,self.col)
  end
  print(">",self.x-10,self.cur*self.spc+self.y,self.col)
 end

 function m:draw()
  self:cur_draw()
 end

 return m:new(nil)
end

function main_menu_init()
 main_menu=menu()
 main_menu:add_choice("player", rp_loop) 
 main_menu:add_choice("instructions", inst_loop)
 
 function main_menu:draw()
  print("space repair!",20,20,7)
  self:cur_draw()
 end 

 function main_menu:something_else()

 end

end

-->8
--ships
ships={}
function ship(init)
 local s=init or {
  --set props
 }

 function s:new(o)
  local o=o or {}
  setmetatable(o,self)
  self.__index=self
  return o
 end

 function s:update()
 --update
 end

 function s:draw()
 --draw
 end

 new_ship=ship_cls:new(nil)
 add(ships,new_ship)
 return new_ship
end

-->8
--rooms
function room(init)
 local r=init or {
  --set props
 }

 function r:new(o)
  local o=o or {}
  setmetatable(o,self)
  self.__index=self
  return o
 end

 function r:update()
 --update
 end

 function r:draw()
 --draw
 end

 return r:new(nil)
end
-->8
--components
function component(init)
 local c=init or {
  --set props
 }

 function c:new(o)
  local o=o or {}
  setmetatable(o,self)
  self.__index=self
  return o
 end

 function c:update()
 --update
 end

 function c:draw()
 --draw
 end

 return c:new(nil)
end
-->8
--update
function title_update()
 update_ticks()
 main_menu:update()
end

function rp_update()
 update_ticks()
end

function inst_update()
 update_ticks()
end

-->8
--draw
function title_draw()
 cls()
 main_menu:draw()
end

function rp_draw()
 cls()
 print("rp",20,20,7)
end

function inst_draw()
 cls()
 print("inst",20,20,7)
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
