local function get_velocity(v, yaw, y)
	local x = -math.sin(yaw) * v
	local z =  math.cos(yaw) * v
	return {x = x, y = y, z = z}
end

local function get_sign(i)
	if i == 0 then
		return 0
	else
		return i/math.abs(i)
	end
end

local function get_v(v)
	return math.sqrt(v.x ^ 2 + v.z ^ 2)
end

local drone = {
    hp_max = 1,
    physical = true,
    weight = 1,
    collisionbox = {-0.15,-0.15,-0.15, 0.15,0.15,0.15},
    visual = "mesh",
    visual_size = {x=1, y=1},
    mesh = "drone.obj",
    textures = {"default_stone.png"}, -- number of required textures depends on visual
    is_visible = true,
    makes_footstep_sound = false,
    automatic_rotate = false,
}

minetest.register_entity("drone:drone", drone)


minetest.register_craftitem("drone:telecomande1", {
	description = "Telecomande decollage",
	inventory_image = "default_apple.png",
	on_use = function(itemstack, user, pointed_thing)
		decollage(itemstack, user, pointed_thing)
	end,
})

minetest.register_craftitem("drone:telecomande2", {
	description = "Telecomande atterissage",
	inventory_image = "default_apple.png",
	on_use = function(itemstack, user, pointed_thing)
		atterissage(itemstack, user, pointed_thing)
	end,
})

function decollage( ... )
	-- body
end

function drone:on_rightclick(clicker)
	if not clicker or not clicker:is_player() then
		return
	end
	if self.driver and clicker == self.driver then
		clicker:set_detach()
		self.driver = nil
		self.object:set_animation({x=0,y=1},0, 0)
		minetest.sound_stop(self.soundHandle)
	elseif not self.driver then
		self.driver = clicker
		clicker:set_attach(self.object, "", {x=0,y=14,z=0}, {x=0,y=0,z=0})
	end
end

function drone:on_activate(self, staticdata, dtime_s)
	self.object:set_armor_groups({immortal = 1})
	if staticdata then
		self.v = tonumber(staticdata)
	end
	self.last_v = self.v
end

function drone:on_step(dtime)	
	self.v = get_v(self.object:getvelocity()) * get_sign(self.v)
	if self.driver then
		local ctrl = self.driver:get_player_control()
		local yaw = self.object:getyaw()
		if ctrl.up then
			self.v = self.v + 0.1
		elseif ctrl.down then
			self.v = self.v - 0.1
		end
		if ctrl.left then
			if self.v < 0 then
				self.object:setyaw(yaw - (1 + dtime) * 0.03)
			else
				self.object:setyaw(yaw + (1 + dtime) * 0.03)
			end
		elseif ctrl.right then
			if self.v < 0 then
				self.object:setyaw(yaw + (1 + dtime) * 0.03)
			else
				self.object:setyaw(yaw - (1 + dtime) * 0.03)
			end
		end
	end
end

minetest.register_craftitem("drone:drone", {
	description = "Drone",
	tiles = {"default_stone.png"},
	drawtype = "mesh",
	mesh = "drone.obj",
	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type ~= "node" then
			return
		end
		if minetest.get_node(pointed_thing.above).name ~= "air" then
			return
		end
		drone = minetest.add_entity(pointed_thing.above, "drone:drone")
		itemstack:take_item()
		return itemstack
	end,
})