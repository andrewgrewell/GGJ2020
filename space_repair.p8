pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
--trek support
--andrew grewell, pete soloway, ryan saul

function _init()
  load_components()
  load_ships()
  title_init()
end

function title_init()
 main_menu_init()
 _update=title_update
 _draw=title_draw
end

function rp_init()

 current_ship=1
  --debug rooms
  poke(0x5f2d, 1)
  tile_size = 16
  room_max = 112
  rooms = ships[current_ship].rooms
  -- rooms = {
  --  room(1, {2,3,0,0}),
  --  room(2, {0,0,1,0}),
  --  room(3, {0,0,4,1}),
  --  room(4, {3,0,0,5}),
  --  room(5, {0,4,0,0}),
  -- }
  inst_player = player(1)
  _update=rp_update
  _draw=rp_draw
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

function do_nothing()

end

-->8
--main menu
function menu(init)
 local m=init or {
  --set props
  curs=1,
  choices={},
  back_func={name="",func=function() end,args={}},
  x=40,
  y=30,
  spc=10,
  col=11,
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
  local choice=self.choices[self.curs]
  choice.func(choice.args)
 end

 function m:set_back_func(name,func,args)
  self.back_func={name=name,func=func,args=args}
 end

 function m:execute_back_func()
  self.back_func.func(self.back_func.args)
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
   if btnp(5) and #self.choices>0 then self:execute_choice() end
   if btnp(4) then self:execute_back_func() end
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
 main_menu:add_choice("player", code_init)
 main_menu:add_choice("instructions", inst_loop)

 function main_menu:draw()
  print("trek support",20,20,11)
  self:ycurs_draw()
 end
end

function change_to_ships_inst()
 inst_menu.state=SHIP_ST
end

function inst_menu_init()
 SHIP_ST=1
 ROOM_ST=2
 FIXR_ST=3
 inst_menu={
  state=SHIP_ST,
  selected_ship=1,
  selected_room=1,
  ships_menu={},
  ship_room_menus={}
 }

 inst_menu.ships_menu=ships_instructions_init()
 for i=1,#ships do
  local fixes={}
  local ship = ships[i]
  for j=1,#ship.rooms do
   add(fixes,fixes_instructions_init(ship.rooms[j]))
  end
  add(inst_menu.ship_room_menus,{menu=ship_rooms_instructions_init(ship),fixes=fixes})
 end

 function inst_menu:update()
  if self.state==SHIP_ST then self.ships_menu:update()
  elseif self.state==ROOM_ST then self.ship_room_menus[self.selected_ship].menu:update()
  elseif self.state==FIXR_ST then self.ship_room_menus[self.selected_ship].fixes[self.selected_room]:update() end
 end

 function inst_menu:draw()
  if self.state==SHIP_ST then self.ships_menu:draw()
  elseif self.state==ROOM_ST then self.ship_room_menus[self.selected_ship].menu:draw()
  elseif self.state==FIXR_ST then self.ship_room_menus[self.selected_ship].fixes[self.selected_room]:draw() end
 end
end

function change_to_rooms_inst(ship)
 inst_menu.state=ROOM_ST
 inst_menu.selected_ship=ship
end

function ships_instructions_init()
 local ship_inst=menu()
 ship_inst.paging=true
 ship_inst.col=11
 for i=1,#ships do
  ship_inst:add_choice("ship "..i,change_to_rooms_inst,i)
 end
 ship_inst:set_back_func("back",inst_menu_init)

 function ship_inst:draw()
  self:draw_left_right_arrows()
  ships[self.curs]:draw_ship_diagram()
  draw_select_button()
  draw_back_button()
 end
 return ship_inst
end

function ship_rooms_instructions_init(ship)
 local room_inst=menu()
 room_inst.paging=true
 room_inst.col=11
 for i=1,#ship.rooms do
  room_inst:add_choice("room "..i,change_to_fix_inst,i)
 end
 room_inst:set_back_func("back",change_to_ships_inst)

 function room_inst:draw()
  self:draw_left_right_arrows()
  ship.rooms[self.curs].machine:draw_inst()
  draw_select_button()
  draw_back_button()
 end

 function room_inst:update()
  self:curs_update()
  ship.rooms[self.curs].machine:update()
 end

 return room_inst
end

function change_to_fix_inst(room)
 inst_menu.state=FIXR_ST
 inst_menu.selected_room=room
end

function fixes_instructions_init(machine)
 local fix_inst=menu()
 fix_inst.paging=true
 fix_inst.col=11
 fix_inst:set_back_func("back",change_to_rooms_inst,inst_menu.selected_ship)

 function fix_inst:draw()
  print("lzxjnkja akliajwljl:",10,10,11)
  draw_check_mark(48,50,11)
  spr(0,40,56,2,2)
  print("⬆️⬆️⬆️➡️",64,64,self.col) --TODO: draw the code to fix here
  draw_back_button()
 end
 return fix_inst
end

function input(text,maxi)
 local inp=init or {
   --set props
  text=text,
  x=40,
  y=40,
  col=11,
  vals=0,
  current="",
  maxi=maxi,
  space=20,
  border=4
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

  if btnp(4) and #self.current>0 then self.current=sub(self.current,1,#self.current-1) end
 end

 function inp:ready()
  if #self.current==self.maxi then return true else return false end
 end

 function inp:update()
  self:enter_keys()
 end

 function inp:draw()
  rectfill(0,0,128,128,1)
  print(self.text,self.x-12,self.y-20,self.col)
  rectfill(self.x-self.border+1,self.y-self.border+1,self.x+self.border+self.maxi*8-1,self.y+self.border+8-1,0)

  if self:ready() then
   rect(self.x-self.border,self.y-self.border,self.x+self.border+self.maxi*8,self.y+self.border+8,11)
   print("confirm?",self.x,self.y+self.border+10,self.col)
  end

  print(self.current,self.x,self.y,self.col)
 end

 return inp:new(nil)
end

function code_enter_init()
 code_enter=input("enter partner code",4)

 function code_enter:update()
  self:enter_keys()
  if self:ready() and btnp(5) then
   set_rand(self.current)
   rp_init()
  end
 end
end

function draw_select_button()
 print("oiaj:🅾️",10,118,11)
end

function draw_back_button()
 print("aoaq:❎",94,118,11)
end

-->8
--ships
ships={}
function ship()
 local s={
  --set props
  rooms={},
  ship_layout={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
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

 function s:add_room(room)
  add(self.rooms,room)
 end

 function s:new(o)
  local o=o or {}
  setmetatable(o,self)
  self.__index=self
  return o
 end

 function s:update()
  foreach(self.rooms,function(r) r:update() end)
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

function spc_print(string,x,y,col,xspc,yspc)
 local ys=y
 local xs=0
 for i=1,#string do
  if sub(string,i,i)=="\n" then ys=ys+(8+yspc); xs=0
  else xs+=1; print(sub(string,i,i),x+xs*(4+xspc),ys,col) end
 end
end

function add_ship_with_rooms(rooms,description)
 nship=ship()
 nship.description=description
 for i=1,#rooms do
  local r=room(rooms[i].id,rooms[i].neighs)
  r:unpack_machine_components(rooms[i].machine)
  nship:add_room(r)
 end
 nship:create_ship_layout()
end

function load_components()
 TOP=1
 MID=2
 LEFT=3
 RIGHT=4
 top_components={
  component('antenna',32,34,TOP),
  component('dish',36,38,TOP),
  component('electrical',40,42,TOP),
  component('light',44,46,TOP)
 }

 mid_components={
  component('readout',64,66,MID),
  component('teleport',68,70,MID),
  component('chair',72,74,MID),
  component('vat',76,78,MID),
 }

 left_components={
  component('scale',96,98,LEFT),
  component('wires',100,102,LEFT),
  component('tube',104,106,LEFT),
  component('sad',108,110,LEFT)
 }

 right_components={
  component('scale',96,98,RIGHT),
  component('wires',100,102,RIGHT),
  component('tube',104,106,RIGHT),
  component('sad',108,110,RIGHT)
 }
end

function load_ships()
 --ship 1
 add_ship_with_rooms({
 {id=1,neighs={0,0,0,2},machine={{1,{false,false,false}},{2,{false,false,false}},{3,{false,false,false}},{4,{false,false,false}}}},
 {id=2,neighs={3,1,4,5},machine={{4,{false,true,true}},{3,{true,true,true}},{2,{true,true,true}},{2,{true,true,true}}}},
 {id=3,neighs={0,0,2,0},machine={{2,{false,true,true}},{1,{true,true,true}},{4,{true,true,true}},{1,{true,true,true}}}},
 {id=4,neighs={2,0,0,0},machine={{3,{false,true,true}},{2,{true,true,true}},{1,{true,true,true}},{3,{true,true,true}}}},
 {id=5,neighs={0,2,0,0},machine={{1,{false,true,true}},{4,{true,true,true}},{2,{true,true,true}},{2,{true,true,true}}}}},
 "oiajoi ;oij;oa wdjoij\noaio jwwoi owi jwda\naoijo;aiwjoaoi")
 --ship 2
 add_ship_with_rooms({
 {id=1,neighs={0,0,0,3},machine={{2,{false,true,true}},{1,{false,true,true}},{3,{false,true,true}},{2,{false,true,true}}}},
 {id=2,neighs={0,0,3,5},machine={{3,{false,true,true}},{2,{true,true,true}},{2,{true,true,true}},{1,{true,true,true}}}},
 {id=3,neighs={2,1,4,0},machine={{1,{false,true,true}},{3,{true,true,true}},{1,{true,true,true}},{3,{true,true,true}}}},
 {id=4,neighs={3,0,0,6},machine={{1,{false,true,true}},{4,{true,true,true}},{4,{true,true,true}},{1,{true,true,true}}}},
 {id=5,neighs={0,2,0,0},machine={{4,{false,true,true}},{1,{true,true,true}},{3,{true,true,true}},{4,{true,true,true}}}},
 {id=6,neighs={0,4,0,0},machine={{3,{false,true,true}},{2,{true,true,true}},{1,{true,true,true}},{1,{true,true,true}}}}},
 "oiajoi ;oij;oa wdjoij\noaio jwwoi owi jwda\naoijo;aiwjoaoi")
 --ship 3
 add_ship_with_rooms({
 {id=1,neighs={0,0,0,2},machine={{1,{true,true,true}},{4,{false,true,true}},{2,{true,true,true}},{4,{true,true,true}}}},
 {id=2,neighs={0,1,0,4},machine={{2,{false,true,true}},{3,{true,true,true}},{3,{true,true,true}},{2,{false,true,true}}}},
 {id=3,neighs={0,0,4,0},machine={{3,{true,true,true}},{2,{true,true,true}},{1,{true,true,true}},{1,{true,true,true}}}},
 {id=4,neighs={3,2,5,0},machine={{4,{false,true,true}},{1,{false,true,true}},{4,{true,true,true}},{3,{true,true,true}}}},
 {id=5,neighs={4,0,0,0},machine={{1,{true,true,true}},{4,{true,true,true}},{3,{true,true,true}},{4,{true,true,true}}}}},
 "oiajoi ;oij;oa wdjoij\noaio jwwoi owi jwda\naoijo;aiwjoaoi")
 -- --ship 4
 -- add_ship_with_rooms({
 -- {1,{0,0,0,3}},
 -- {2,{0,0,3,5}},
 -- {3,{2,1,4,0}},
 -- {4,{3,0,0,6}},
 -- {5,{0,2,0,0}},
 -- {6,{0,4,0,0}}},
 -- "oiajoi ;oij;oa wdjoij\noaio jwwoi owi jwda\naoijo;aiwjoaoi")
 -- --ship 5
 -- add_ship_with_rooms({
 -- {1,{0,0,0,3}},
 -- {2,{0,0,3,5}},
 -- {3,{2,1,4,6}},
 -- {4,{3,0,0,7}},
 -- {5,{0,2,0,0}},
 -- {6,{0,3,0,0}},
 -- {7,{0,4,0,0}}},
 -- "oiajoi ;oij;oa wdjoij\noaio jwwoi owi jwda\naoijo;aiwjoaoi")
 -- --ship 6
 -- add_ship_with_rooms({
 -- {1,{0,0,2,0}},
 -- {2,{1,0,0,6}},
 -- {3,{0,9,0,7}},
 -- {4,{0,0,5,8}},
 -- {5,{4,0,0,0}},
 -- {6,{0,2,7,0}},
 -- {7,{6,3,8,0}},
 -- {8,{7,4,0,0}},
 -- {9,{0,0,0,3}}},
 -- "oiajoi ;oij;oa wdjoij\noaio jwwoi owi jwda\naoijo;aiwjoaoi")
 -- --ship 7
 -- add_ship_with_rooms({
 -- {1,{0,0,0,3}},
 -- {2,{0,0,0,6}},
 -- {3,{0,1,4,0}},
 -- {4,{3,0,5,0}},
 -- {5,{4,0,6,0}},
 -- {6,{5,2,0,0}}},
 -- "oiajoi ;oij;oa wdjoij\noaio jwwoi owi jwda\naoijo;aiwjoaoi")
 -- --ship 8
 -- add_ship_with_rooms({
 -- {1,{0,0,2,5}},
 -- {2,{1,0,3,0}},
 -- {3,{2,0,0,6}},
 -- {4,{0,0,5,0}},
 -- {5,{4,1,0,0}},
 -- {6,{0,3,7,0}},
 -- {7,{6,0,0,0}}},
 -- "oiajoi ;oij;oa wdjoij\noaio jwwoi owi jwda\naoijo;aiwjoaoi")
 -- --ship 9
 -- add_ship_with_rooms({
 -- {1,{0,0,0,4}},
 -- {2,{0,0,3,0}},
 -- {3,{2,0,4,6}},
 -- {4,{3,1,0,0}},
 -- {5,{0,0,6,0}},
 -- {6,{5,3,0,0}}},
 -- "oiajoi ;oij;oa wdjoij\noaio jwwoi owi jwda\naoijo;aiwjoaoi")
 -- --ship 10
 -- add_ship_with_rooms({
 -- {1,{0,0,0,2}},
 -- {2,{0,1,0,3}},
 -- {3,{0,2,4,0}},
 -- {4,{3,5,0,6}},
 -- {5,{0,0,0,4}},
 -- {6,{0,4,0,0}}},
 -- "oiajoi ;oij;oa wdjoij\noaio jwwoi owi jwda\naoijo;aiwjoaoi")
end

-->8
--rooms
function room(id, neighs)
 local r=init or {
  id = id,
  spawn_x = 64,
  spawn_y = 80,
  neighs = neighs,
  machine = machine(),
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

 function r:unpack_machine_components(m) --TODO: current matches desired, need to mix this up
  local top_current,top_desired = self:unpack_single_component(top_components[m[1][1]],m[1][2],m[1][2])
  self.machine:add_top_component(top_current,top_desired)

  local left_current,left_desired = self:unpack_single_component(left_components[m[2][1]],m[2][2],m[2][2])
  self.machine:add_left_component(left_current,left_desired)

  local mid_current,mid_desired = self:unpack_single_component(mid_components[m[3][1]],m[3][2],m[3][2])
  self.machine:add_middle_component(mid_current,mid_desired)

  local right_current,right_desired = self:unpack_single_component(right_components[m[4][1]],m[4][2],m[4][2])
  self.machine:add_right_component(right_current,right_desired)
 end

 function r:unpack_single_component(comp,current,desired)
  local c_cur = comp
  c_cur.blinking=current[1]
  c_cur.sparking=current[2]
  c_cur.smoking=current[3]
  local c_des = comp
  c_des.blinking=desired[1]
  c_des.sparking=desired[2]
  c_des.smoking=desired[3]
  return c_cur,c_des
 end

 function r:new(o)
  local o=o or {}
  setmetatable(o,self)
  self.__index=self
  return o
 end

 function r:update()
  self.machine:update()
 end

 function r:draw()
  self:draw_base()
  self:draw_doors()
  self.machine:draw()
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
  self.top_component.current:update()
  self.top_component.desired:update()
  self.left_component.current:update()
  self.left_component.desired:update()
  self.middle_component.current:update()
  self.middle_component.desired:update()
  self.right_component.current:update()
  self.right_component.desired:update()
 end

 function m:draw()
  x=56
  y=48
  self.top_component.current:draw(x,y)
  self.left_component.current:draw(x-16,y+16)
  self.middle_component.current:draw(x,y+16)
  self.right_component.current:draw(x+16,y+16)
 end

 function m:draw_inst()
  local x=50
  local y=24
  local col=11
  print("aoibowieq oimoijoiq!",x-46,y-8,col)
  self.top_component.desired:draw(x,y)
  print("oijad",x+20,y+8,col)
  draw_check_mark(x-10,y+10,col)
  self.left_component.desired:draw(x,y+24)
  print("oijad",x+20,y+32,col)
  draw_check_mark(x-10,y+34,col)
  self.middle_component.desired:draw(x,y+48)
  print("oijad",x+20,y+56,col)
  draw_check_mark(x-10,y+58,col)
  self.right_component.desired:draw(x,y+72)
  print("oijad",x+20,y+80,col)
  draw_check_mark(x-10,y+82,col)
 end

 function m:draw_fix()

 end

 return m:new(nil)
end

function draw_check_mark(x,y,col)
 line(x,y,x+6,y-6,col)
 line(x,y+1,x+6,y-5,col)
 line(x,y,x-2,y-2,col)
 line(x,y+1,x-2,y-1,col)
end
--
-- function scramble_letter(l)
--  --TODO: make this scramble each letter several places
-- end

function component(name,base,alt,type)
 local comp={
  --set props
  blinking=false,
  sparking=false,
  smoking=false,
  name=name,
  base_spr=base,
  alt_spr=alt,
  type=type,
  blink_tick=tick(15),
  spark_tick=tick(15), -- TODO: Pixel animation
  smoke_tick=tick(15), -- TODO: Move smoke sprite
  current_spr=base
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
  if self.blink_tick:ready() and self.blinking == true then
   if self.current_spr == self.base_spr then self.current_spr=self.alt_spr else self.current_spr=self.base_spr end
   self.blink_tick:trigger()
  end
 end

 function comp:draw(x,y)
  flipx=false
  if type==RIGHT then flipx=true end
  spr(self.current_spr,x,y,2,2,flipx)
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
 ships[current_ship]:update()
 -- foreach(rooms,function(o) o:update() end)
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
 -- if (inst_player.room_index)
 -- then rooms[inst_player.room_index]:draw()
 -- end

 rooms[inst_player.room_index]:draw()
 inst_player:draw()
 draw_target()
end

function draw_target()
 local mx = stat(32)-1
 local my = stat(33)-1
 local clipped_x = flr(mx/tile_size) * tile_size
 local clipped_y = flr(my/tile_size) * tile_size
 local half_size = tile_size * 0.5
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
0000000606000000000070767670700000006666660000000000000066666600c67cc7c7ccc7776cc777c777c77cc77c00000000000000000000000000000000
0000000666000000000070766670700000066ddddd60000000000006ddddd660c67ccc77c0ccc76cc67777c7cc7cc76c00000000000000000000000000000000
00000000d000000000000007d70000000066dd76666600000000006dd6676d66c66c0cccc000c66cc67c7cc7777cc76c0000000dd00000000000000dd0000000
00000000600000000000070060070000006dd76d6666d00000000d6d66d676660060000000000600006ccccccccc060000000666666000000000066666600000
00000000600000000000000767000000006d66ddd666d00000000d6d6ddd666600d7000000007d0000d7000000007d0000006026620600000000608668060000
00000000600000000000000060000000006d666dd666d00000000d6d6dd66666000600000000600000070000000070000000622662260000000068e66e860000
000000006000000000000000600000000006d666666dd00000000dd6666666600006000000006000000600000000600000006216612600000000687667860000
000000006000000000000000600000000000666666dd0000000000dd66666600000d70000007d000000d70000007d00000006216612600000000687667860000
0000000060000000000000006000000000000dddddd000000000000dddddd0000000700000070000000060000006000000006216612600000000687667860000
00000000600000000000000060000000000000000d000000000000000d0000000000d700007d00000000d700007d000000006216612600000000687667860000
000000dd6dd00000000000dd6dd000000000ddddddddd0000000ddddddddd00000000677776000000000067777600000000dd21dd12dd000000dde7dd7edd000
0000006666600000000000666660000000066666666dd00000066666666dd000000066dddd660000000066dddd66000000066666666660000006666666666000
06666666666666600666666666666660000d06000060d000000d07000070d0000000eeeeeeee00000000eeeeeeee000006666666666666600666666666666660
6dd7777777777dd66dd6666666666dd6000d06000060d000000d07cccc70d000000ee888888ee000000ee888888ee000d66666666666666dd66666666666666d
dd711111111117dddd6111cccc1116dd000d06000060d000000d07cccc70d00006688888888886600668888888888660dddddddddddddddddddddddddddddddd
dd1ccccc11ccccddddccccc77cc111dd000d06000060d000000d0cc77cc0d0006dd8888888888dd66dd8888888888dd60dddddddddddddd00dddddddddddddd0
ddcc777c1cc77cdddd77cc7777ccccdd000d06000060d000000d0c7777c0d000ddd8888888888dddddd8888888888ddd0b333aabbbaa33b00b333bbbbbb333b0
dd77cc7ccc7cc7ddddc77c7cc77cc7dd000d06000060d000000dcc7777ccd000dddd18888881dddddddd18888881dddd0b333aabbbb3a3b00b333bbbabb333b0
dd7cccc7c77cccddddcc777cccc777dd000d06000060d000000dcc7777ccd000dddd11111111dddddddd11111111dddd0b333bbbbbb333b00b33abbbbbaa33b0
ddcc11cc7ccc11dddd1c77cc11cc7cdd000d06000060d000000dc777c77cd000deee1dddddd1eeeddeee1dddddd1eeed0b333bbbabb333b00b333bbbbbaa33b0
dd11111ccc1111dddd1cccc1111cccdd000d06000060d000000dc7c7777cd000eeee1dddddd1eeeeeeee1dddddd1ebee0b33abbbbbaa33b00b333baabbb333b0
dd111111111111dddd111111111111dd000d06000060d000000dc777c77cd000888811111111888888881111111188880b333bbbbbaa33b00b3a3baabbb333b0
dd666666666666dddd777777777777dd006d66666666d600007dc7c7cc7cd70011eeeeeeeeeeee1111eeeeeeeeeeee110b333baabbb333b00b333bbbbbba33b0
dddddddddddddddddddddddddddddddd066d66dddd66d66007cdc7cccc7cdc7011888eeeeee8881111888eeeeee888110b3a3baabbb333b00b333bbbbbb333b0
dddddddddddddddddddddddddddddddd066d6dc77cd6d66007cdcc7777ccdc70118888888888881111888888888888116b333bbbbbba33b66b33abbbbaa333b6
1ddd11111111ddd11ddd11111111ddd10d6d66666666d6d00d7dc777777cd7d011111111111111111111111111111111d66666666666666dd66666666666666d
111110000001111111111000000111110dddddddddddddd00dddddddddddddd01dddd110011dddd11dddd110011dddd1dddddddddddddddddddddddddddddddd
01ddd000000ddd1001ddd000000ddd1000dddddddddddd0000dddddddddddd001dddd110011dddd11dddd110011dddd10dddddddddddddd00dddddddddddddd0
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
d1d666666666666dd66666666666666dd1d666666661111122222222222222211222222222222221d66dddd111111111d66dddd111111111d66dddd111111111
d1d66666666661111111111111111111d1d666666661111122222222222222211222222222222221111111111111111111111111111111111111111111111111
ddd66666666611111111111111111111ddd666666661111122222222222222211222222222222221111111111111111111111111111111111111111111111111
d1d66666666111111111111111111111d1d666666661111122222222222222211222222222222221111111111111111111111111111111111111111111111111
d1d66666666111111111111111111111d1d666666661111122222222222222211222222222222221111111111111111111111111111111111111111111111111
ddddddddddd111111111111111111111ddddddddddd1111122222222222222211222222222222221111111111111111111111111111111111111111111111111
000000000000000000000000000000000000000000000000ddd1111111111111ddd0000001111111ddd000000111111100000000000000000000000000000000
000000000000000000000000000000000000000000000000d1dccccccc111111d1d0000001111111d1d000000111111100000555000000000000000000000000
000000000000000000000000000000000000000000000000d1dccccccc111111d1d0000001111111d1d000000111111100000555055500000000000000000000
000000000000000000000000000000000000000000000000dddccccccc111111ddd0000001111111ddd000000111111100050555055500000cc0000000000000
000000000000000000000000000000000000000000000000d1dccccccc111111d1d1111111111111d1d000000111111100005500055500000cc0c00000000000
ddddddddddddddddddddddddddddddddddddddddddddddddd1dccccccc111111d1dccccccc111111d1d000000111111100555555000000000000000000000000
1d11d11dd11d11d11d11d11dd11d11d11d11d11dd11d11d1ddddcccccc111111ddddcccccc111111dddd0000011111110005555505500000cc00000c00000000
ddddddddddddddddddddddddddddddddddddddddddddddddd1ddcccccc111111d1ddcccccc111111d1dd0000011111110005555505500500cc000c0000000000
1222211111ccccc11222211111c100001222211111000000d1dddccccc111111d1dddccccc111111d1ddd0000111111100055555000000000000000000000000
12221111ccccccc112221111ccc100001222111100000000ddddddddddd11111ddddddddddd11111ddddddddddd11111000555555500000000cc0c0000000000
1222121cccccccc11222121cccc100001222121000000000d1ddd66666d11111d1ddd66666d11111d1ddd66666d11111000000055500000000cc0000c0000000
1222121cccccccc11222121cccc100001222121000000000d1d6ddddddd11111d1d6ddddddd11111d1d6ddddddd1111100500555550500000000c00000000000
1222121cccccccc11222121cccc100001222121000000000ddd6666666d11111ddd6666666d11111ddd6666666d1111100000550000000000000000000000000
1222121cccccccc11222121cccc100001222121000000000d1d6666666611111d1d6666666611111d1d666666661111100005005500000000000000c00000000
1222121cccccccc11222121cccc100001222121000000000d1d6666666611111d1d6666666611111d1d6666666611111000000555050000000000000c0000000
122111111111111112211111111100001221111000000000ddddddddddd11111ddddddddddd11111ddddddddddd1111100000055000000000000000000000000
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
00000000000000000000000000000000bbbb00000000bbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000bbbb00000000bbbb00000000000000000000000000000000000000000000000000007000000700000000000000000000
00000000000000000000000000000000bb000000000000bb00000000000000000000000000000000000000000000000000000700007000000000000000000000
000000bb000000000000000000000000bb000000000000bb00000000000000000000000000000000000000000000000000000600006000000000099999900000
00000bb00000000000b0000000000000000000000000000000000000000000000000000000000000000000000000000000000dccccd000000000999999990000
0bb0bb00000000000bbb00000000000000000000000000000000000000000000000000000000000000000000000000000000c777777c00000000999999990000
00bbb00000000000bbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000c77777777c0000000999999990000
000b0000000000000bbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000c7777117777c000000499999940000
000000000000000000bbbbb000000000000000000000000000000000000000000000000000000000000000000000000000c7771071777c000000044444400000
0000000000000000000bbbbb00000000000000000000000000000000000000000000000000000000000000000000000000c777c001777d000000009999000000
00000000000000000000bbbbb0000000000000000000000000000000000000000000000000000000000000000000000000d7677c17777d000000094994900000
000000000000000000000bbbbb00000000000000000000000000000000000000000000000000000000000000000000000007667777776c000000094994900000
0000000000000000000000bbbbb00000bb000000000000bb00000000000000000000000000000000000000000000000000007667c11cc0000000094994900000
00000000000000000000000bbbbb0000bb000000000000bb00000000000000000000000000000000000000000000000000000777777700000000004444000000
000000000000000000000000bbbbb000bbbb00000000bbbb00000000000000000000000000000000000000000000000000000000000000000000009009000000
0000000000000000000000000bbbbb00bbbb00000000bbbb00000000000000000000000000000000000000000000000000000000000000000000009009000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000002021000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000003031000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000064654849000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000074755859000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000a00001620016200162001720018200192001c2001e20022200272002c2002f20032200322003220032200322003320033200322003220032200322003120031200302002e2002d2002c2002c2002620000000
000100201262007600006000560000600136000060000600006000060000000006000060000600006000060000620006000060000600006000060000600006000060000600006000060000600006000060000600
0006000000600016000360006600086000b6000e6001260014600176001b9001b90026900269002690026900269002690026900269001b9001b9001760014600116000e6000a6000860006600046000360001600
000c000031516365063d5060050600506005060050600506005060050600506005060050600506005060050600506005060050600506005060050600506005060050600506005060050600506005060050600506
000c0000135031c053245532750300503005030050300503005030050300503005033a50300503005030050300503005030050300503005030050300503005030050300503005030050300503005030050300503
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0010000d1622116221162211722118221192211c2211e22122221272212c2012f20132201322013220132201322013320133201322013220132201322013120131201302012e2012d2012c2012c2012620100000
000600000060102611076210c631106311263114631176311963119631196211b90126951269512695126951269512695126951269511b9011a6211a6311a631196311663114631116310d631096210461101601
