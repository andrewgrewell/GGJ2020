pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
function _init()
  load_ships()
  title_init()
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
  poke(0x5f2d, 1)
  tile_size = 16
  room_max = 112
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
  curs=1,
  choices={},
  x=40,
  y=30,
  spc=10,
  col=7,
  paging=false,
 }

 function m:new(o)
  local o=o or {}
  setmetatable(o,self)
  self.__index=self
  return o
 end

 function m:add_choice(name,func,args)
  add(self.choices,{name=name,func=func,args=args})
 end

 function m:execute_choice()
  self.choices[self.curs].func()
 end

 function m:curs_update()
  if input_tick:ready() then
   if self.paging then
    if btnp(0) and self.curs>1 then self.curs-=1
    elseif btnp(1) and self.curs<#self.choices then self.curs+=1 end
   else
    if btnp(2) and self.curs>1 then self.curs-=1
    elseif btnp(3) and self.curs<#self.choices then self.curs+=1 end
   end
   if btnp(4) then self:execute_choice() end
  end
 end

 function m:update()
  self:curs_update()
 end

 function m:ycurs_draw()
  for i=1,#self.choices do
   print(self.choices[i].name,self.x,i*self.spc+self.y,self.col)
  end
  print(">",self.x-10,self.curs*self.spc+self.y,self.col)
 end

 function m:draw_left_right_arrows()
  local lpt={x=20,y=64}
  local rpt={x=104,y=64}
  local w=8
  local h=8
  local t=3
  for i=0,t do
   if self.curs>1 then
    line(lpt.x+i,lpt.y,lpt.x+w+i,lpt.y-h,self.col)
    line(lpt.x+i,lpt.y,lpt.x+w+i,lpt.y+h,self.col)
   end
   if self.curs<#self.choices then
    line(rpt.x-i,rpt.y,rpt.x-w-i,rpt.y-h,self.col)
    line(rpt.x-i,rpt.y,rpt.x-w-i,rpt.y+h,self.col)
   end
  end
 end

 function m:draw()
  self:ycurs_draw()
 end

 return m:new(nil)
end

function main_menu_init()
 main_menu=menu()
 main_menu:add_choice("player", rp_init)
 main_menu:add_choice("instructions", code_init)

 function main_menu:draw()
  print("space repair!",20,20,7)
  self:ycurs_draw()
 end
end

function inst_menu_init()
 SHIP_ST=1
 ROOM_ST=2
 FIXR_ST=3
 inst_menu={
  state=SHIP_ST
 }

 inst_menu.ships_menu=ship_instructions_init()
 for i=1,#ships do
  room_instructions_init(ships[i])
  for i=1,#ships[i].rooms do
   fixes_instructions_init(ships[i].rooms[i])
  end
 end

 function inst_menu:draw()
  if self.state==SHIP_ST then
 end
end

function change_to_room_inst(ship)

end

function ship_instructions_init()
 local ship_inst=menu()
 ship_inst.paging=true
 ship_inst.col=11
 for i=1,#ships do
  ship_inst:add_choice("ship "..i,change_to_room_inst,{ships[i]})
 end

 function ship_inst:draw()
  self:draw_left_right_arrows()
  ships[self.curs]:draw_ship_diagram()
 end
 return ship_inst
end

function change_to_fix_inst(machine)

end

function room_instructions_init(ship)
 local room_inst=menu()
 room_inst.paging=true
 room_inst.col=11
 for i=1,#ship.rooms do
  room_inst:add_choice("room "..i,change_to_fix_inst,{ship.rooms[i].machine})
 end

 function room_inst:draw()
  print(self.curs,64,64,self.col)
 end
 return room_inst
end

function fixes_instructions_init()

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
function ship()
 local s={
  --set props
  rooms={},
  ship_layout={0,0,0,0,0,0,0,0,0,0,0,0,0,0},
  rm_col=11,
  cord_col=11,
  dspc=11,
  rmsize=3,
  xmax=0,
  xmin=128,
  ymax=0,
  ymin=128,
  xoff=0,
  yoff=0
 }

 function s:add_rooms(array_of_rooms)
  --Must be in format {{1,{1,2,3,4},{2,{0,1,0,0}, ... }
  for i=1,#array_of_rooms do
   self:add_room(array_of_rooms[i][1],array_of_rooms[i][2])
  end
 end

 function s:add_room(id,neighs)
  add(self.rooms,{id=id,neighs=neighs})
 end

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
  self:draw_ship_diagram()
 end

 function s:draw_ship_diagram()
  local xoff=-(((self.xmax-self.xmin)/2)+self.xmin-64)-4
  local yoff=-(((self.ymax-self.ymin)/2)+self.ymin-64)
  for i=1,#self.ship_layout do
    if self.ship_layout[i]!=0 then
     local rm=self.ship_layout[i]
     if rm.neighs[1]!=0 then line(rm.x+xoff,rm.y+yoff,rm.x+xoff-self.dspc,rm.y+yoff,self.cord_col) end
     if rm.neighs[2]!=0 then line(rm.x+xoff,rm.y+yoff,rm.x+xoff,rm.y-self.dspc+yoff,self.cord_col) end
     if rm.neighs[3]!=0 then line(rm.x+xoff,rm.y+yoff,rm.x+xoff+self.dspc,rm.y+yoff,self.cord_col) end
     if rm.neighs[4]!=0 then line(rm.x+xoff,rm.y+yoff,rm.x+xoff,rm.y+self.dspc+yoff,self.cord_col) end
     circfill(rm.x+xoff,rm.y+yoff,self.rmsize,self.rm_col)
   end
  end
  spc_print(self.description,10,10,11,0,1)
  print("oiaj:🅾️",10,118,11)
  print("aoaq:❎",94,118,11)
 end

 function s:create_ship_layout()
  self:pos_room(self.rooms[1],64,64)
 end

 function s:pos_room(room,x,y)
  if x>self.xmax then self.xmax=x end
  if x<self.xmin then self.xmin=x end
  if y>self.ymax then self.ymax=y end
  if y<self.ymin then self.ymin=y end
  self.ship_layout[room.id]={x=x,y=y,neighs=room.neighs}
  local w=room.neighs[1]
  local n=room.neighs[2]
  local e=room.neighs[3]
  local s=room.neighs[4]
  if w != 0 and self.ship_layout[w]==0 then self:pos_room(self.rooms[w],x-self.dspc,y) end
  if n != 0 and self.ship_layout[n]==0 then self:pos_room(self.rooms[n],x,y-self.dspc) end
  if e != 0 and self.ship_layout[e]==0 then self:pos_room(self.rooms[e],x+self.dspc,y) end
  if s != 0 and self.ship_layout[s]==0 then self:pos_room(self.rooms[s],x,y+self.dspc) end
 end

 new_ship=s:new(nil)
 add(ships,new_ship)
 return new_ship
end

function add_ship_with_rooms(rooms,description)
 nship=ship()
 nship.description=description
 nship:add_rooms(rooms)
 nship:create_ship_layout()
end

function spc_print(string,x,y,col,xspc,yspc)
 local ys=y
 local xs=0
 for i=1,#string do
  if sub(string,i,i)=="\n" then ys=ys+(8+yspc); xs=0
  else xs+=1; print(sub(string,i,i),x+xs*(4+xspc),ys,col) end
 end
end

function load_ships()
 --ship 1
 add_ship_with_rooms({
 {1,{0,0,0,2}},
 {2,{3,1,4,5}},
 {3,{0,0,2,0}},
 {4,{2,0,0,0}},
 {5,{0,2,0,0}}},
 "oiajoi ;oij;oa wdjoij\noaio jwwoi owi jwda\naoijo;aiwjoaoi")
 --ship 2
 add_ship_with_rooms({
 {1,{0,0,0,3}},
 {2,{0,0,3,5}},
 {3,{2,1,4,0}},
 {4,{3,0,0,6}},
 {5,{0,2,0,0}},
 {6,{0,4,0,0}}},
 "oiajoi ;oij;oa wdjoij\noaio jwwoi owi jwda\naoijo;aiwjoaoi")
 --ship 3
 add_ship_with_rooms({
 {1,{0,0,0,2}},
 {2,{0,1,0,4}},
 {3,{0,0,4,0}},
 {4,{3,2,5,0}},
 {5,{4,0,0,0}}},
 "oiajoi ;oij;oa wdjoij\noaio jwwoi owi jwda\naoijo;aiwjoaoi")
 --ship 4
 add_ship_with_rooms({
 {1,{0,0,0,3}},
 {2,{0,0,3,5}},
 {3,{2,1,4,0}},
 {4,{3,0,0,6}},
 {5,{0,2,0,0}},
 {6,{0,4,0,0}}},
 "oiajoi ;oij;oa wdjoij\noaio jwwoi owi jwda\naoijo;aiwjoaoi")
 --ship 5
 add_ship_with_rooms({
 {1,{0,0,0,3}},
 {2,{0,0,3,5}},
 {3,{2,1,4,6}},
 {4,{3,0,0,7}},
 {5,{0,2,0,0}},
 {6,{0,3,0,0}},
 {7,{0,4,0,0}}},
 "oiajoi ;oij;oa wdjoij\noaio jwwoi owi jwda\naoijo;aiwjoaoi")
 --ship 6
 add_ship_with_rooms({
 {1,{0,0,2,0}},
 {2,{1,0,0,6}},
 {3,{0,9,0,7}},
 {4,{0,0,5,8}},
 {5,{4,0,0,0}},
 {6,{0,2,7,0}},
 {7,{6,3,8,0}},
 {8,{7,4,0,0}},
 {9,{0,0,0,3}}},
 "oiajoi ;oij;oa wdjoij\noaio jwwoi owi jwda\naoijo;aiwjoaoi")
 --ship 7
 add_ship_with_rooms({
 {1,{0,0,0,3}},
 {2,{0,0,0,6}},
 {3,{0,1,4,0}},
 {4,{3,0,5,0}},
 {5,{4,0,6,0}},
 {6,{5,2,0,0}}},
 "oiajoi ;oij;oa wdjoij\noaio jwwoi owi jwda\naoijo;aiwjoaoi")
 --ship 8
 add_ship_with_rooms({
 {1,{0,0,2,5}},
 {2,{1,0,3,0}},
 {3,{2,0,0,6}},
 {4,{0,0,5,0}},
 {5,{4,1,0,0}},
 {6,{0,3,7,0}},
 {7,{6,0,0,0}}},
 "oiajoi ;oij;oa wdjoij\noaio jwwoi owi jwda\naoijo;aiwjoaoi")
 --ship 9
 add_ship_with_rooms({
 {1,{0,0,0,4}},
 {2,{0,0,3,0}},
 {3,{2,0,4,6}},
 {4,{3,1,0,0}},
 {5,{0,0,6,0}},
 {6,{5,3,0,0}}},
 "oiajoi ;oij;oa wdjoij\noaio jwwoi owi jwda\naoijo;aiwjoaoi")
 --ship 10
 add_ship_with_rooms({
 {1,{0,0,0,2}},
 {2,{0,1,0,3}},
 {3,{0,2,4,0}},
 {4,{3,5,0,6}},
 {5,{0,0,0,4}},
 {6,{0,4,0,0}}},
 "oiajoi ;oij;oa wdjoij\noaio jwwoi owi jwda\naoijo;aiwjoaoi")
end

-->8
--rooms
function room(id, neighs, machine)
 local r=init or {
  id = id,
  spawn_x = 64,
  spawn_y = 80,
  neighs = neighs,
  machine = machine,
  floor_color = 1,
  walls = {
   top_corner = 128,
   top = 130,
   side_left = 132,
   bottom_corner = 134,
   bottom = 136,
  },
  doors = {
   top = 138,
   bottom = 160,
   side_left= 166
  },
  paths = {
   { {64, 80}, {48, 80}, {32, 80}, {16,80}, {16,64} },
   { {64, 80}, {48, 80}, {32, 80}, {36,64}, {32, 48}, {32,32}, {48, 32}, {48, 16}, {48, 0} },
   { {64, 80}, {80, 80}, {96, 80}, {96, 64} },
   { {64, 80}, {64, 96}, {64, 112} }
  }
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
 end

 function r:draw_base()
  --we use a solid color for the door
  cls(self.floor_color)
  --top-corners
  spr(self.walls.top_corner, 0, 0, 2, 2)
  sspr(0, 64, tile_size, tile_size, room_max, 0, tile_size, tile_size, true)
  --top
  for i = 16, room_max - tile_size, tile_size do
   spr(self.walls.top, i, 0, 2, 2)
  end
  --sides
  for i = 16, room_max, tile_size do
   spr(self.walls.side_left, 0, i, 2, 2)
   sspr(32, 64, tile_size, tile_size, room_max, i, tile_size, tile_size, true)
  end
  --bottom corners
  spr(self.walls.bottom_corner, 0, room_max, 2, 2)
  sspr(48, 64, tile_size, tile_size, room_max, room_max, tile_size, tile_size, true)
  --bottom
  for i = 16, room_max - tile_size, tile_size do
   spr(self.walls.bottom, i, room_max, 2, 2)
  end
 end
 --end draw_base

 function r:draw_doors()
  local tile_start = tile_size * 3
  for i = 1, #self.neighs do
   --left-doors
   if (i == 1 and self.neighs[i] > 0) then
     local x = 0
     local y = tile_start
     sspr(48, 80, tile_size, tile_size, x, y, tile_size, tile_size, false, true)
     spr(self.doors.side_left, x, y + tile_size, 2, 2)
   end
   --top-doors
   if (i == 2 and self.neighs[i] > 0) then
     local x = tile_start
     local y = 0
     spr(self.doors.top, x, y, 2, 2)
     sspr(80, 64, tile_size, tile_size, x + tile_size, y, tile_size, tile_size, true)
   end
   --right-doors
   if (i == 3 and self.neighs[i] > 0) then
     local x = room_max
     local y = tile_start
     sspr(48, 80, tile_size, tile_size, x, y + tile_size, tile_size, tile_size, true)
     sspr(48, 80, tile_size, tile_size, x, y, tile_size, tile_size, true, true)
   end
   --bottom-doors
   if (i == 4 and self.neighs[i] > 0) then
     local x = tile_start
     local y = 128 - tile_size
     spr(self.doors.bottom, x, y, 2, 2)
     sspr(0, 80, tile_size, tile_size, x + tile_size, y, tile_size, tile_size, true)
   end
  end
 end
 -- end raw_doors

 function r:draw_components()

 end

 return r:new(nil)
end
-->8
--machines
function machine()
 local m={
  --set props
  top_component={},
  left_component={},
  middle_component={},
  right_component={}
 }

 function m:add_top_component(current,desired)
  self.top_component={current=current,desired=desired}
 end

 function m:add_left_component(current,desired)
  self.left_component={current=current,desired=desired}
 end

 function m:add_middle_component(current,desired)
  self.middle_component={current=current,desired=desired}
 end

 function m:add_right_component(current,desired)
  self.right_component={current=current,desired=desired}
 end

 function m:new(o)
  local o=o or {}
  setmetatable(o,self)
  self.__index=self
  return o
 end

 function m:update()
 --update
 end

 function m:draw()
 --draw

 end

 return m:new(nil)
end

function component()
 local comp={
  --set props
  blinking=false,
  sparking=false,
  smoking=false,
 }

 function comp:set_sprites(base,alt)
  self.base_spr=base
  self.alt_spr=alt
 end

 function comp:new(o)
  local o=o or {}
  setmetatable(o,self)
  self.__index=self
  return o
 end

 function comp:update()
 --update
 end

 function comp:draw()
 --draw
 end

 return comp:new(nil)
end

-->8
--player
function player(room_index)
 local p = {
  room_index = room_index,
  x = rooms[room_index].spawn_x,
  y = rooms[room_index].spawn_y,
  moving = false,
  sprites ={
   idle = 8,
   down = 0,
   up = 4,
   side_right = 10
  }
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
  if self.moving then return nil end
  local room = rooms[self.room_index]
  --left
  if btnp(0) and room.neighs[1] > 0 then self:exit_room(room.neighs[1], 1)
  --right
  elseif btnp(1) and room.neighs[3] > 0 then self:exit_room(room.neighs[3], 3)
   --up
  elseif btnp(2) and room.neighs[2] > 0 then self:exit_room(room.neighs[2], 2)
   --down
  elseif btnp(3) and room.neighs[4] > 0 then self:exit_room(room.neighs[4], 4)
  end
 end

 function p:exit_room(room_index, dir)
  self.moving = true
  local paths = rooms[room_index].paths
  local path = paths[dir]

  local c = cocreate(function()
   for i=1,#path do
      self.x = path[i][1]
      self.y = path[i][2]
      yield()
      yield()
      sfx(10)
      yield()
      yield()
      yield()
      yield()
    end
    --todo open the door when the player is at the last node of the path
    self.room_index = room_index
    --we enter a room using the opposite path, and walking it backwards
    local oppsite_index = dir + 2
    if oppsite_index > 4 then oppsite_index = oppsite_index - 4; end
    self:enter_room(paths[oppsite_index])
  end)
  add(coroutines, c)
 end

 function p:enter_room(path)
  self.x = path[#path][1]
  self.y = path[#path][2]
  local c = cocreate(function()
   for i=#path,1, -1 do
      self.x = path[i][1]
      self.y = path[i][2]
      yield()
      sfx(10)
      yield()
      yield()
      yield()
      yield()
      yield()
    end
    self.moving = false
  end)
  add(coroutines, c)
 end

 function p:draw()
 	--only draw if in room
  if (self.room_index == nil)
  then return nil
  end
  --todo animations and stuff
  spr(self.sprites.down,self.x, self.y, 2, 2)
 end

 return p:new(nil)
end
--end-player


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
 update_coroutines()
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
 draw_target()
end

function draw_target()
 local mx = stat(32)-1
 local my = stat(33)-1
 local clipped_x = flr(mx/tile_size) * tile_size
 local clipped_y = flr(my/tile_size) * tile_size
 local half_size = tile_size * 0.5
 print(clipped_x..", "..clipped_y, 25,25)
 rect(clipped_x, clipped_y, clipped_x + tile_size, clipped_y + tile_size, 8)
end

function inst_draw()
 cls()
 inst_menu:draw()
end

function code_draw()
 cls()
 code_enter:draw()
end

-- corutine manager
coroutines = {}
function update_coroutines()
 for c in all(coroutines) do
   if costatus(c) then
     coresume(c)
   else
     del(coroutines,c)
   end
 end
end

-- objects

-- door
function create_door(props)
 local d = {
  open = props.open,
  anim_index = 0,
  type = props.type,
  x = props.x,
  y = props.y,
 }

 function d:new()
  local o = {}
  setmetatable(o,self)
  self.__index=self
  return o
 end

 function d:update()
  if self.open then anim_index = 2 end
 end

 function d:draw()
  self:draw_door()
 end

 function d:draw_door()
  local tile_start = tile_size * 3
  for i = 1, #self.neighbors do
   --left-doors
   if (self.type == "left") then
     local x = 0
     local y = tile_start
     sspr(48 + anim_index * 16, 80, tile_size, tile_size, x, y, tile_size, tile_size, false, true)
     spr(self.doors.side_left + 2 * anim_index, x, y + tile_size, 2, 2)
   end
   --top-doors
   if (self.type == "top") then
     local x = tile_start
     local y = 0
     spr(self.doors.top + 2 * anim_index, x, y, 2, 2)
     sspr(80 + anim_index * 16, 64, tile_size, tile_size, x + tile_size, y, tile_size, tile_size, true)
   end
   --right-doors
   if (self.type == "right") then
     local x = room_max
     local y = tile_start
     sspr(48 + anim_index * 16, 80, tile_size, tile_size, x, y + tile_size, tile_size, tile_size, true)
     sspr(48 + anim_index * 16, 80, tile_size, tile_size, x, y, tile_size, tile_size, true, true)
   end
   --bottom-doors
   if (self.type == "bottom") then
     local x = tile_start
     local y = 128 - tile_size
     spr(self.doors.bottom + 2 * anim_index, x, y, 2, 2)
     sspr(0 + anim_index * 16, 80, tile_size, tile_size, x + tile_size, y, tile_size, tile_size, true)
   end
  end
 end

 function d:open()
  local c = cocreate(function()
   for i=#path,1, -1 do
      self.anim_index = min(self.anim_index+1, 2)
      yield()
      yield()
      yield()
      yield()
      yield()
      yield()
    end
    --todo sound fx
  end)
  add(coroutines, c)
 end

 return c:new(nil)
end

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
000dddddddddddddddddddddddddddddddddddddddd11111ddd00000000000000000000000000000dddddddddddddddddddddddddddddddddddddddddddddddd
00dd11d11d11d11dd11d11d11d11d11dd1d6666666611111d1d00000000000000000000000000000d11d11d11d11d11dd11d11d11d11d11dd11d11d11d11d11d
0dddddddddddddddddddddddddddddddd1d6666666611111d1d00000000000000000000000000000dddddddddddddddddddddddddddddddddddddddddddddddd
ddddd6666666666dd66666666666666dddd6666666611111d1dd0000000000000000000000000000d6666dddddccccc1d6666dddddc10000d6666ddddd000000
d1dd66666666666dd66666666666666dd1d6666666611111ddddd000000000000000000000000000d666ddddccccccc1d666ddddccc10000d666dddd00000000
d1d666666666666dd66666666666666dd1d66666666111112dddddddddddddddddddddddddddddddd666d6dcccccccc1d666d6dcccc10000d666d6d000000000
ddd666666666666dd66666666666666dddd666666661111122dd11d11d11d11d1d11d11dd11d11d1d666d6dcccccccc1d666d6dcccc10000d666d6d000000000
d1d666666666666dd66666666666666dd1d6666666611111222dddddddddddddddddddddddddddddd666d6dcccccccc1d666d6dcccc10000d666d6d000000000
d1d666666666666dd66666666666666dd1d666666661111122222222222222211222222222222221d666d6dcccccccc1d666d6dcccc10000d666d6d000000000
ddd666666666666dd66666666666666dddd666666661111122222222222222211222222222222221d666d6dcccccccc1d666d6dcccc11111d666d6d111111111
d1d666666666666dd66666666666666dd1d666666661111122222222222222211222222222222221d66ddddcccccccc1d66ddddcccc11111d66dddd111111111
d1d66666666661111111111111111111d1d666666661111122222222222222211222222222222221111111111111111111111111111111111111111111111111
ddd66666666611111111111111111111ddd666666661111122222222222222211222222222222221111111111111111111111111111111111111111111111111
d1d66666666111111111111111111111d1d666666661111122222222222222211222222222222221111111111111111111111111111111111111111111111111
d1d66666666111111111111111111111d1d666666661111122222222222222211222222222222221111111111111111111111111111111111111111111111111
ddddddddddd111111111111111111111ddddddddddd1111122222222222222211222222222222221111111111111111111111111111111111111111111111111
000000000000000000000000000000000000000000000000ddd1111111111111ddd0000001111111ddd000000111111100000000000000000000000000000000
000000000000000000000000000000000000000000000000d1dcccccccc11111d1d0000001111111d1d000000111111100000000000000000000000000000000
000000000000000000000000000000000000000000000000d1dcccccccc11111d1d0000001111111d1d000000111111100000000000000000000000000000000
000000000000000000000000000000000000000000000000dddcccccccc11111ddd0000001111111ddd000000111111100000000000000000000000000000000
000000000000000000000000000000000000000000000000d1dcccccccc11111d1d1111111111111d1d000000111111100000000000000000000000000000000
ddddddddddddddddddddddddddddddddddddddddddddddddd1dcccccccc11111d1dcccccccc11111d1d000000111111100000000000000000000000000000000
1d11d11dd11d11d11d11d11dd11d11d11d11d11dd11d11d1ddddccccccc11111ddddccccccc11111dddd00000111111100000000000000000000000000000000
ddddddddddddddddddddddddddddddddddddddddddddddddd1ddccccccc11111d1ddccccccc11111d1dd00000111111100000000000000000000000000000000
1222211111ccccc11222211111c100001222211111000000d1dddcccccc11111d1dddcccccc11111d1ddd0000111111100000000000000000000000000000000
12221111ccccccc112221111ccc100001222111100000000ddddddddddd11111ddddddddddd11111ddddddddddd1111100000000000000000000000000000000
1222121cccccccc11222121cccc100001222121000000000d1ddd66666d11111d1ddd66666d11111d1ddd66666d1111100000000000000000000000000000000
1222121cccccccc11222121cccc100001222121000000000d1d6ddddddd11111d1d6ddddddd11111d1d6ddddddd1111100000000000000000000000000000000
1222121cccccccc11222121cccc100001222121000000000ddd6666666d11111ddd6666666d11111ddd6666666d1111100000000000000000000000000000000
1222121cccccccc11222121cccc100001222121000000000d1d6666666611111d1d6666666611111d1d666666661111100000000000000000000000000000000
1222121cccccccc11222121cccc100001222121000000000d1d6666666611111d1d6666666611111d1d666666661111100000000000000000000000000000000
1221111cccccccc11221111cccc100001221111000000000ddddddddddd11111ddddddddddd11111ddddddddddd1111100000000000000000000000000000000
ddddddddddddddddddddddddddddddddd111111111111111ddddddddddddddddddddddddddddddddddddddddddddddddd1ddddddddd11111d1ddddddddd11111
1d11d11dd11d11d11d11d11dd11d11d1d1111111111111111d11d11dd11d11d11d11d11dd11d11d11d11d11dd11d11d1ddd6666666611111ddd6666666611111
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
00000000000000000000000000000000bbbb00000000bbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000bbbb00000000bbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000bb000000000000bb00000000000000000000000000000000000000000000000000000000000000000000000000000000
000000bb000000000000000000000000bb000000000000bb00000000000000000000000000000000000000000000000000000000000000000000099999900000
00000bb00000000000b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000999999990000
0bb0bb00000000000bbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000999999990000
00bbb00000000000bbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000999999990000
000b0000000000000bbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000499999940000
000000000000000000bbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044444400000
0000000000000000000bbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009999000000
00000000000000000000bbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000094994900000
000000000000000000000bbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000094994900000
0000000000000000000000bbbbb00000bb000000000000bb00000000000000000000000000000000000000000000000000000000000000000000094994900000
00000000000000000000000bbbbb0000bb000000000000bb00000000000000000000000000000000000000000000000000000000000000000000004444000000
000000000000000000000000bbbbb000bbbb00000000bbbb00000000000000000000000000000000000000000000000000000000000000000000009009000000
0000000000000000000000000bbbbb00bbbb00000000bbbb00000000000000000000000000000000000000000000000000000000000000000000009009000000
__sfx__
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00040000105200e510115100951000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
