pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
function _init()
  title_init()
  rp_init()
end

function title_init()
 main_menu_init()
 _update=title_update
 _draw=title_draw
end

function rp_init()
 _update=rp_update
 _draw=rp_draw
  --debug rooms
  tile_size = 16
  wall_sprite = 130
  floor_sprite = 128
  door_sprite = 132
  room_center_x = 64
  room_center_y = 80
  rooms = {
   room(1, {2,3,0,0}),
   room(2, {0,0,1,0}),
   room(3, {0,0,4,1}),
   room(4, {3,0,0,5}),
   room(5, {0,4,0,0}),
  }
  inst_player = player(1)
end

function code_init()
 code_enter_init()
 _update=code_update
 _draw=code_draw
end

function inst_loop()
 inst_menu_init()
 _update=inst_update
 _draw=inst_draw
end

function set_rand(string)
 d=0
 for i=1,#string do
  if sub(string,i,1)=='⬆️' then d+=1
  elseif sub(string,i,1)=='⬇️' then d+=2
  elseif sub(string,i,1)=='⬅️' then d+=3
  elseif sub(string,i,1)=='➡️' then d+=4 end
 end
 srand(d)
 random=rnd()
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
   if btnp(2) and self.cur>1 then
    self.cur-=1
   elseif btnp(3) and self.cur<#self.choices then
    self.cur+=1
   end
   if btnp(4) then self:execute_choice() end
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
 main_menu:add_choice("player", rp_init)
 main_menu:add_choice("instructions", code_init)

 function main_menu:draw()
  print("space repair!",20,20,7)
  self:cur_draw()
 end

 function main_menu:something_else()

 end
end


function inst_menu_init()
 inst_menu=menu()
 inst_menu:add_choice("ships", ship_display)
 inst_menu:add_choice("rooms", room_display)

 function inst_menu:draw()
  print(random,100,100,7)
  self:cur_draw()
 end

end


function input(text,maxi)
 local inp=init or {
   --set props
  text=text,
  x=40,
  y=40,
  col=7,
  vals=0,
  current="",
  maxi=maxi,
  space=20,
  border=3
 }

 function inp:new(o)
  local o=o or {}
  setmetatable(o,self)
  self.__index=self
  return o
 end

 function inp:enter_keys()
  if btnp()>0 and input_tick:ready() and #self.current<self.maxi then
   if btnp(0) then self.current=self.current.."⬅️"
   elseif btnp(1) then self.current=self.current.."➡️"
   elseif btnp(2) then self.current=self.current.."⬆️"
   elseif btnp(3) then self.current=self.current.."⬇️" end
  end

  if btnp(5) and #self.current>0 then self.current=sub(self.current,1,#self.current-1) end
 end

 function inp:ready()
  if #self.current==self.maxi then return true else return false end
 end

 function inp:update()
  self:enter_keys()
 end

 function inp:draw()
  if self:ready() then
   rectfill(self.x-self.border,self.y-self.border,self.x+self.border+self.maxi*8,self.y+self.space+self.border+8,2)
   print("confirm?",self.x,self.y+self.border+10,7)
  end

  print(self.text,self.x,self.y,self.col)
  print(self.current,self.x,self.y+self.space,self.col)
 end

 return inp:new(nil)
end

function code_enter_init()
 code_enter=input("input code",4)

 function code_enter:update()
  self:enter_keys()
  if self:ready() and btnp(4) then
   set_rand(self.current)
   inst_loop()
  end
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

 new_ship=s:new(nil)
 add(ships,new_ship)
 return new_ship
end

-->8
--rooms
function room(id, neighbors, components)
 local r=init or {
  id = id,
  neighbors = neighbors,
  components = components
 }

 function r:new(o)
  local o=o or {}
  setmetatable(o,self)
  self.__index=self
  return o
 end

 function r:update()

 end

 function r:draw()
  self:draw_base()
  self:draw_doors()
  print("room_id:"..self.id, 25, 35)
  print("player_room_id: "..inst_player.room_index, 25, 45)
 end

 function r:draw_base()
  for yy = 0, 128, tile_size do
   local y = yy
   for xx = 0, 128, tile_size do
    local x = xx
    --print(x..", "..y, x, y)
    local is_top = y == 0
    local is_bottom = y == 128 - tile_size
    local is_left = x == 0
    local is_right = x == 128 - tile_size
    local is_component = false --todo component positions
    local sprite_to_draw = nil
    --todo doors
    --top-left
    if (is_top and is_left) then sprite_to_draw = wall_sprite
    --top
    elseif (is_top) then sprite_to_draw = wall_sprite
    --top-right
    elseif (is_top and is_right) then sprite_to_draw = wall_sprite
    --right
    elseif (is_right) then sprite_to_draw = wall_sprite
    --bottom-right
    elseif (is_right and is_bottom) then sprite_to_draw = wall_sprite
    --bottom
    elseif (is_bottom) then sprite_to_draw = wall_sprite
    --bottom-left
    elseif (is_bottom and is_left) then sprite_to_draw = wall_sprite
    --left
    elseif (is_left) then sprite_to_draw = wall_sprite
    -- floor
    else sprite_to_draw = floor_sprite
    end
    -- draw the tile
    spr(sprite_to_draw, x, y, 2, 2)
   end
  end
 end
 --end draw_base

 function r:draw_doors()
  local tile_start = tile_size * 3
  for i = 1, #self.neighbors do
   --left-doors
   if (i == 1 and self.neighbors[i] > 0) then
     local x = 0
     local y = tile_start
     spr(door_sprite, x, y, 2, 2)
     spr(door_sprite, x, y + tile_size, 2, 2)
   end
   --top-doors
   if (i == 2 and self.neighbors[i] > 0) then
     local x = tile_start
     local y = 0
     spr(door_sprite, x, y, 2, 2)
     spr(door_sprite, x + tile_size, y, 2, 2)
   end
   --right-doors
   if (i == 3 and self.neighbors[i] > 0) then
     local x = 128 - tile_size
     local y = tile_start
     spr(door_sprite, x, y, 2, 2)
     spr(door_sprite, x, y + tile_size, 2, 2)
   end
   --bottom-doors
   if (i == 4 and self.neighbors[i] > 0) then
     local x = tile_start
     local y = 128 - tile_size
     spr(door_sprite, x, y, 2, 2)
     spr(door_sprite, x + tile_size, y, 2, 2)
   end
  end
 end

 return r:new(nil)
end

-->8
--player
function player(room_index)
 local p = {
  room_index = room_index,
  x = room_center_x,
  y = room_center_y,
  leaving_room = false
 }

 function p:new()
  local o = {}
  setmetatable(o,self)
  self.__index=self
  return o
 end

 function p:update()
  self:check_change_room()
 end

 function p:check_change_room()
  local room = rooms[self.room_index]
  --left
  if btnp(0) and room.neighbors[1] > 0 then self:go_to_room(room.neighbors[1])
  --right
 elseif btnp(1) and room.neighbors[3] > 0 then self:go_to_room(room.neighbors[3])
  --up
 elseif btnp(2) and room.neighbors[2] > 0 then self:go_to_room(room.neighbors[2])
  --down
 elseif btnp(3) and room.neighbors[4] > 0 then self:go_to_room(room.neighbors[4])
  end
 end

 function p:go_to_room(room_index)
  --todo animate to the door before setting room index
  --cls()
  --stop("Going to room index: "..room_index)
  self.room_index = room_index;
 end

 function p:draw()
 	--only draw if in room
  if (self.room_index == nil)
  then return nil
  end
  spr(0,self.x, self.y, 2, 2)
 end

 return p:new(nil)
end
--end-player

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
 rooms[inst_player.room_index]:update()
 inst_player:update()
end

function inst_update()
 update_ticks()
 inst_menu:update()
end

function code_update()
 update_ticks()
 code_enter:update()
end

-->8
--draw
function title_draw()
 cls()
 main_menu:draw()
end

function rp_draw()
 cls()
 if (inst_player.room_index)
 then rooms[inst_player.room_index]:draw()
 end
 inst_player:draw()
end

function inst_draw()
 cls()
 inst_menu:draw()
 print(d,5,120,7)
end

function code_draw()
 cls()
 code_enter:draw()
end

--
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000999999000000000000000000000000009999990000000000000000000000000000000000000000009999990000000000000000000000000099999900000
00009999999900000000099999900000000099999999000000000999999000000000099999900000000099999999000000000999999000000000999999990000
000099cccc99000000009999999900000000999999990000000099999999000000009999999900000000999999c0000000009999999900000000999999c00000
000099cccc990000000099cccc9900000000999999990000000099999999000000009999999900000000999999c000000000999999c000000000999999c00000
000049cccc940000000099cccc9900000000499999940000000099999999000000009999999900000000499999c000000000999999c000000000499999c00000
0000044444400000000049cccc94000000000444444000000000499999940000000049999994000000000444444000000000499999c000000000044444400000
00000000000000000000044444400000000000999900000000000444444000000000044444400000000000000000000000000444444000000000000000000000
0000099ee990000000000000000000000000094994900000000000999900000000000099990000000000099999e0000000000000000000000000099999e00000
00000998899000000000099ee990000000000949949000000000094994900000000009499490000000000999998000000000099999e000000000099999800000
00000999999000000000099889900000000009499490000000000949949000000000044994400000000009999990000000000999998000000000099999900000
00000090040000000000099999900000000000444400000000000949949000000000004994000000000000400900000000000999999000000000009004000000
00000090090000000000004004000000000000900900000000000044440000000000004444000000000000900900000000000004900000000000009009000000
00000000090000000000009009000000000000000900000000000090090000000000009009000000000000900000000000000009900000000000009000000000
0000000000000000000000077700000000000000000000000000000000000000000000cccccc0000000000000cccccc000000000000000000000000000000000
000000000000000000000700000700000000000000000000000000000000000000ccccc7777c0000000000000c7777c000000000000000000000000000000000
000000000000000000000007770000000000000000000000000000000000000000c77cc7cc7cc0000ccc0000cc7cc7c000000000000000000000000000000000
0000000666000000000070766670700000000000000000000000000000000000ccc77cc7cc77cccccc7cccccc7ccc7cc00000000000000000000000000000000
0000000606000000000070767670700000066666600000000000000666666000c67cc7c7ccc7776cc777c777c77cc77c00000000000000000000000000000000
000000066600000000007076667070000066ddddd60000000000006ddddd6600c67ccc77c0ccc76cc67777c7cc7cc76c00000000000000000000000000000000
00000000d000000000000007d7000000066dd76666600000000006dd6676d660c66c0cccc000c66cc67c7cc7777cc76c0000000dd00000000000000dd0000000
0000000060000000000007006007000006dd76d6666d00000000d6d66d6766600060000000000600006ccccccccc060000000666666000000000066666600000
0000000060000000000000076700000006d66ddd666d00000000d6d6ddd6666000d7000000007d0000d7000000007d0000006026620600000000608668060000
0000000060000000000000006000000006d666dd666d00000000d6d6dd666660000600000000600000070000000070000000622662260000000068e66e860000
00000000600000000000000060000000006d666666dd00000000dd66666666000006000000006000000600000000600000006216612600000000687667860000
00000000600000000000000060000000000666666dd0000000000dd666666000000d70000007d000000d70000007d00000006216612600000000687667860000
000000006000000000000000600000000000dddddd000000000000dddddd00000000700000070000000060000006000000006216612600000000687667860000
0000000060000000000000006000000000000000d000000000000000d00000000000d700007d00000000d700007d000000006216612600000000687667860000
000000dd6dd00000000000dd6dd00000000ddddddddd0000000ddddddddd000000000677776000000000067777600000000dd21dd12dd000000dde7dd7edd000
000000666660000000000066666000000066666666dd00000066666666dd0000000066dddd660000000066dddd66000000066666666660000006666666666000
06666666666666600666666666666660000d06000060d000000d07000070d0000000eeeeeeee00000000eeeeeeee00000d666666666666d00d666666666666d0
6dd7777777777dd66dd6666666666dd6000d06000060d000000d07cccc70d000000ee888888ee000000ee888888ee0000dddddddddddddd00dddddddddddddd0
dd711111111117dddd6111cccc1116dd000d06000060d000000d07cccc70d0000008888888888000000888888888800000dddddddddddd0000dddddddddddd00
dd1ccccc11ccccddddccccc77cc111dd000d06000060d000000d0cc77cc0d0000008888888888000000888888888800000b3abbbabaa3b0000b33bbbbbb3ab00
ddcc777c1cc77cdddd77cc7777ccccdd000d06000060d000000d0c7777c0d0000008888888888000000888888888800000b33aabbbaa3b0000b33bbbbbb33b00
dd77cc7ccc7cc7ddddc77c7cc77cc7dd000d06000060d000000dcc7777ccd0000000188888810000000018888881000000b33aabbbb3ab0000b3abbbabaa3b00
dd7cccc7c77cccddddcc777cccc777dd000d06000060d000000dcc7777ccd0000000111111110000000011111111000000b33bbbbbb33b0000b33bbbbbaa3b00
ddcc11cc7ccc11dddd1c77cc11cc7cdd000d06000060d000000dc777c77cd0000eee11dddd11eee00eee11dddd11eee000b33bbbabb33b0000b33baabbb33b00
dd11111ccc1111dddd1cccc1111cccdd000d06000060d000000dc7c7777cd000eee811dddd118eeeeee811dddd118ebe00b3abbbbbaa3b0000ba3baabbb33b00
dd111111111111dddd111111111111dd000d06000060d000000dc777c77cd0008888111111118888888811111111888800b33bbbbbaa3b0000b33bbbbbba3b00
dd666666666666dddd777777777777dd006d66666666d600007dc7c7cc7cd700011eeeeeeeeee110011eeeeeeeeee11000b33baabbb33b0000b33bbbbbb33b00
dddddddddddddddddddddddddddddddd066d66dddd66d66007cdc7cccc7cdc7000d88eeeeee88d0000d88eeeeee88d0000ba3baabbb33b0000b33babbbb33b00
dddddddddddddddddddddddddddddddd066d6dc77cd6d66007cdcc7777ccdc700008888888888000000888888888800006b33bbbbbba3b6006b33bbbaab33b60
1ddd11111111ddd11ddd11111111ddd10d6d66666666d6d00d7dc777777cd7d0000111111111100000011111111110000d666666666666d00d666666666666d0
111110000001111111111000000111110dddddddddddddd00dddddddddddddd0000dd111111dd000000dd111111dd0000dddddddddddddd00dddddddddddddd0
01ddd000000ddd1001ddd000000ddd1000dddddddddddd0000dddddddddddd00000dd100001dd000000dd100001dd00000dddddddddddd0000dddddddddddd00
00000000000000000000000000000000000000000000000600000000000000060000000000000000000000000000000000000000000000000000000000000000
0000000066666666000000006666666600000001111111160000000cccccccc60000000000000000000000000000000000000000000000000000000000000000
00000066dddddddd00000066dddddddd0000001888888886000000c2222222260000000000000000000000000000000000066666666660000006666666666000
000006dddddddddd000006dddddddddd000001880dddddd600000c22066666d60000000000000000000000000000000000063333333360000006333333336000
00006ddddd1111dd00006ddddd1111dd0000110bddbbbbbd0000cc036633333d000000000000000000000000000000000006333333336000000633b33b336000
0006dddd111222dd0006dddd111222dd000810bdd00222260002c03660088886000000000000006600000000000000660006333333336d660006333333336d66
006dddd1177222dd006dddd1177222dd000810bd0220000d0002c0360880000d000000006d6d6ddd000000006d6d6ddd0006333333336ddd0006333bb3336ddd
006ddd11777722dd006ddd11777722dd00081aaa22aaaaad0002c9998899999d00000006ddddd1dd00000006ddddd1dd0006333333336000000633b33b336000
06dddd17777722dd06dddd17787722dd00881ad02000000d0022c9608000000d0000006dd1d1d1dd0000006dd1d1d1dd00063333333360000006333333336000
06ddd117777772dd06ddd117778772dd008a10d2200000000029c06880000000000000ddd11111dd000000ddd11111dd00066666666660000006666666666000
06ddd177887772dd06ddd177772872dd00aa1dd2000000000099c668000000000000006d111dd1dd0000006d111dd1dd0000000dd00000000000000dd0000000
06ddd177728877dd06ddd177777287dd00a01db2000000000090c63800000000000000ddd1d000dd000000ddd1d000dd00000006600000000000000660000000
06ddd177777288dd06ddd177777728dd00a01db2000000000090c038000000000000006dd1d000000000006dd1d0000000000006600000000000000660000000
06ddd666666666dd06ddd666666666dd00a01db2000000000090c03800000000000000d111100000000000d11110000000000006600000000000000660000000
06dddddddddddddd06dddddddddddddd6dad1dd2600000006d9dc6d86000000000000666666600000000066686660000000000d66d000000000000d66d000000
06dddddddddddddd06ddddddddddddddd6666666d0000000d6666666d000000000000ddddddd000000000ddddddd000000000066660000000000006666000000
000dddddddddddddddddddddddddddddddddddddddd11111d1d00000000000000000000000000000dddddddddddddddddddddddddddddddddddddddddddddddd
00dd11d11d11d11dd11d11d11d11d11dd1d6666666611111d1dd0000000000000000000000000000d11d11d11d11d11dd11d11d11d11d11dd11d11d11d11d11d
0dddddddddddddddddddddddddddddddd1d6666666611111ddddd000000000000000000000000000dddddddddddddddddddddddddddddddddddddddddddddddd
ddddd6666666666dd66666666666666dddd66666666111111dddddddddddddddddddddddddddddddd6666ddddd66666dd6666ddddd6d0000d6666ddddd000000
d1dd66666666666dd66666666666666dd1d666666661111111dd11d11d11d11d1d11d11dd11d11d1d666dddd6666666dd666dddd666d0000d666dddd00000000
d1d666666666666dd66666666666666dd1d6666666611111111dddddddddddddddddddddddddddddd666d6d66666666dd666d6d6666d0000d666d6d000000000
ddd666666666666dd66666666666666dddd66666666111111111111111111111d11111111111111dd666d6d66666666dd666d6d6666d0000d666d6d000000000
d1d666666666666dd66666666666666dd1d66666666111111111111111111111d11111111111111dd666d6d66666666dd666d6d6666d0000d666d6d000000000
d1d666666666666dd66666666666666dd1d66666666111111111111111111111d11111111111111dd666d6d66666666dd666d6d6666d0000d666d6d000000000
ddd666666666666dd66666666666666dddd66666666111111111111111111111d11111111111111dd666d6d66666666dd666d6d6666d1111d666d6d111111111
d1d666666666666dd66666666666666dd1d66666666111111111111111111111d11111111111111dd66dddd66666666dd66dddd6666d1111d66dddd111111111
d1d66666666661111111111111111111d1d66666666111111111111111111111d11111111111111d111111111111111111111111111111111111111111111111
ddd66666666611111111111111111111ddd66666666111111111111111111111d11111111111111d111111111111111111111111111111111111111111111111
d1d66666666111111111111111111111d1d66666666111111111111111111111d11111111111111d111111111111111111111111111111111111111111111111
d1d66666666111111111111111111111d1d666666661111111111111111111111111111111111111111111111111111111111111111111111111111111111111
ddddddddddd111111111111111111111ddddddddddd1111111111111111111111111111111111111111111111111111111111111111111111111111111111111
000000000000000000000000000000000000000000000000ddddddddddd11111ddd0000001111111ddd000000111111100000000000000000000000000000000
000000000000000000000000000000000000000000000000d1d6666666611111d1d0000001111111d1d000000111111100000000000000000000000000000000
000000000000000000000000000000000000000000000000d1d6666666611111d1d0000001111111d1d000000111111100000000000000000000000000000000
ddddddddddddddddddddddddddddddddddddddddddddddddddd6666666611111ddd0000001111111ddd000000111111100000000000000000000000000000000
1d11d11dd11d11d11d11d11dd11d11d11d11d11dd11d11d1d1d6666666611111d1ddddddddd11111d1d000000111111100000000000000000000000000000000
ddddddddddddddddddddddddddddddddddddddddddddddddd1d6666666611111d1d6666666611111d1d000000111111100000000000000000000000000000000
d1111ddddd11111dd1111ddddd1d0000d1111ddddd000000dddd666666611111dddd666666611111dddd00000111111100000000000000000000000000000000
d111dddd1111111dd111dddd111d0000d111dddd00000000d1dd666666611111d1dd666666611111d1dd00000111111100000000000000000000000000000000
d111d6d11111111dd111d6d1111d0000d111d6d000000000d1ddd66666611111d1ddd66666611111d1ddd0000111111100000000000000000000000000000000
d111d6d11111111dd111d6d1111d0000d111d6d000000000ddddddddddd11111ddddddddddd11111ddddddddddd1111100000000000000000000000000000000
d111d6d11111111dd111d6d1111d0000d111d6d000000000d1ddd66666d11111d1ddd66666d11111d1ddd66666d1111100000000000000000000000000000000
d111d6d11111111dd111d6d1111d0000d111d6d000000000d1d6ddddddd11111d1d6ddddddd11111d1d6ddddddd1111100000000000000000000000000000000
d111d6d11111111dd111d6d1111d0000d111d6d000000000ddd6666666d11111ddd6666666d11111ddd6666666d1111100000000000000000000000000000000
d11dddd11111111dd11dddd1111d0000d11dddd000000000d1d6666666611111d1d6666666611111d1d666666661111100000000000000000000000000000000
111111111111111111111111111111111111111111111111d1d6666666611111d1d6666666611111d1d666666661111100000000000000000000000000000000
111111111111111111111111111111111111111111111111ddddddddddd11111ddddddddddd11111ddddddddddd1111100000000000000000000000000000000
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd1ddddddddd11111d1ddddddddd11111
1d11d11dd11d11d11d11d11dd11d11d11d11d11dd11d11d11d11d11dd11d11d11d11d11dd11d11d11d11d11dd11d11d1ddd6666666611111ddd6666666611111
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd1d6666666611111d1d6666666611111
d66666666666666dd66666666666666dd66666666666666dd66666666666666dd66666666666666dd66666666666666dd1d6666666611111d1d6666666611111
d66dddddddddd66dd66dddddddddd66dd66dddddddddd66dd66dddddddddd66dd666dddddddd666dd6666dddddd6666dddd6ddddd6611111ddd66ddddddd1111
d6dd61111611dd6dd6dd11161161dd6dd6dd16116111dd6dd6dd11611116dd6dd666d222222d666dd666d333333d666dd1d6d222d6611111d1d6d333d6dd1111
d6d1111611111d6dd6d1161111111d6dd6d6111111161d6dd6d1111116111d6dd666d2e2ee2d666dd666d3b3bb3d666dd1d6d2e2d6611111d1d6d3b3d6dd1111
d6d1111111611d6dd6d1111161111d6dd6d1116111111d6dd6d1611111116d6dd666d222222d666dd666d333333d666dddd6d2e2d6611111ddd6d3b3d6dd1111
d6dd16111111dd6dd6dd11111116dd6dd6dd11111611dd6dd6dd11161111dd6dd666dddddddd666dd666dddddddd666dddd6d222d6611111ddd6d333d6dd1111
d66dddddddddd66dd66dddddddddd66dd66dddddddddd66dd66dddddddddd66dd66666666666666dd666d666666d666dd1d6d2e2d6611111d1d6d3b3d6dd1111
d66666666666666dd66666666666666dd66666666666666dd66666666666666dd66666666666666dd666dddddddd666dd1d6d222d6611111d1d6d333d6dd1111
111111111111111111111111111111111111111111111111111111111111111111111111111111111111dddddddd1111ddd6ddddd6611111ddd66ddddddd1111
111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111d1d6666666611111d1d6666666611111
111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111d1d6666666611111d1d6666666611111
111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111ddd6666666611111ddd6666666611111
111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111d1ddddddddd11111d1ddddddddd11111
