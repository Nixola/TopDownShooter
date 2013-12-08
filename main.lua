
math.sign = function(x) return math.abs(x)/x end
love.keyboard.setKeyRepeat(.25, .025)


zombies = {
	attack = 10,
	health = 100,
	speed = 110,
	width = 16,
	height = 16,
	move = true}
	
zombies.mt = {__index = zombies}

zombies.spawn = function(self, x, y)
	
	t = setmetatable({}, self.mt)
	t.x, t.y = x, y
	table.insert(zombies, t)
	
end

zombies.spawnHorde = function(self, avgX, avgY, number)

	for i = 1, number do
	
		self:spawn(avgX + math.random(-number*self.width/5, number*self.width/5), avgY + math.random(-number*self.height/5, number*self.height/5))
		
	end
	
end

zombies.update = function(self, dt)

	if self.move then
	
		for i, v in ipairs(self) do
		
			local angle = math.atan2(v.y-player.y, v.x - player.x)-math.pi/2
			local sin, cos = math.sin(angle), -math.cos(angle)
			
			v.x, v.y = v.x+v.speed*sin*dt, v.y+v.speed*cos*dt
			
		end
		
	end

end

zombies.draw = function(self)

	love.graphics.setColor(255,0,0)
	
	for i, zombie in ipairs(self) do
	
		love.graphics.rectangle('fill', zombie.x, zombie.y, zombie.width, zombie.height)
		
	end
	
end


player = {}

	player.x = 392
	player.y = 292
	player.health = 1000
	player.cooldown = 0
	player.speed = 140
	player.move = true
	player.lines = {}
	player.weapons = {
		rifle = {power = 500, cooldown = 1, bullets = 1, spread = 0, pierce = 0, name = 'Rifle'},
		shotgun = {power = 100, cooldown = 1, bullets = 5, spread = math.pi/20, pierce = 0, name = 'Shotgun'},
		uzi = {power = 25, cooldown = 0.05, bullets = 1, spread = math.pi/30, pierce = 0, autofire = true, name = 'Machine gun'},
		heavy = {power = 25, cooldown = 0.08, bullets = 2, spread = math.pi/20, pierce = 0, autofire = true, name = 'Heavy machine gun'},
		laser = {power = 10, cooldown = 0.1, bullets = 1, spread = 0, pierce = 5, autofire = true, name = 'Laser'},
		rocket = {power = 100, cooldown  = 1, bullets = 1, spread = math.pi/100, pierce = 0, name = 'Rocket launcher', explode = {radius = 64, power = 25, fragments = 6, pierce = 3}},
		handgun = {power = 100, cooldown = .25, bullets = 1, spread = math.pi/150, pierce = 0, name = 'Handgun'},
		pierce = {power = 100, cooldown = .25, bullets = 1, spread = 0, pierce = math.huge, name = 'Pierce'},
		list = {'rifle', 'shotgun', 'uzi', 'heavy', 'laser', 'rocket', 'handgun', 'pierce'}}
	player.weapon = player.weapons.rifle
	
	player.collides = function(self, v)
	
		if math.abs(self.x-8 - v.x) >= 16 then return end
		if math.abs(self.y-8 - v.y) >= 16 then return end
		return true
		
	end
	
	player.shoot = function(self, x, y)
	
		self.cooldown = self.weapon.cooldown
		
		local angle = math.atan2(self.y-y, self.x-x)-math.pi*(self.move and 0 or 1)
		
		angle = angle + (math.random()*self.weapon.spread*(math.random(2) == 1 and 1 or -1))
		
		x, y = self.x+math.cos(angle)*150, self.y+math.sin(angle)*150
		
	  --y = mx+q
	  --x = (y-q)/m
		local x1 = self.x
		local x2 = x
		local y1 = self.y
		local y2 = y
		
		local px, py = x1, y1
		local cx, cy = x, y
		
		local m = -(y2-y1)/(x1-x2)
		local q = -(-x1*y2+x2*y1)/(x1-x2)
		hit = {}
		
		for i, v in ipairs(zombies) do
		
			local x1, y1 = v.x, v.y
			local x2, y2 = v.x+v.width, v.y+v.height
			
			if math.sign(px-cx) == math.sign(px-x1) and math.sign(py-cy) == math.sign(py-y1) or (math.sign(px-cx) == math.sign(px-x2) and math.sign(py-cy) == math.sign(py-y2)) then
			
				x1, x2 = math.min(x1, x2), math.max(x1, x2)
				y1, y2 = math.min(y1, y2), math.max(y1, y2)
				
				if (y1 <= m*x1+q and m*x1+q <= y2) or (y1 <= m*x2+q and m*x2+q <= y2) or (x1 <= (y1-q)/m and (y1-q)/m <= x2) or (x1 <= (y2-q)/m and (y2-q)/m <= x2) then
				
					table.insert(hit, v)
					died = true
					
				end
				
			end
			
		end
		
		if died then
		
			table.sort(hit, function(v1, v2)
			
				local dist1 = ((v1.x+8-self.x)^2+(v1.y+8-self.y)^2)^.5
				local dist2 = ((v2.x+8-self.x)^2+(v2.y+8-self.y)^2)^.5
				
				return dist1<dist2
			end)

			local power = self.weapon.power
			
			local pierce = self.weapon.pierce
			
			if not self.weapon.explode then
			
				for i, v in ipairs(hit) do
				
					pierce = pierce - 1
				
					if power > v.health then
					
						power = power - v.health
					
						v.health = 0
						
					elseif power < v.health then
					
						v.health = v.health - power
						
						table.insert(self.lines, {px, py, v.x+8, (v.x+8)*m+q})
						
						if pierce < 0 then
						
							power = 0
						
							break
							
						else
						
							power = self.weapon.power
							
						end
						
					elseif power == v.health then
					
						v.health = 0
						
						power = 0
						
						table.insert(self.lines, {px, py, v.x+8, (v.x+8)*m+q})
						
						if pierce < 0 then
						
							power = 0
						
							break
							
						else
						
							power = self.weapon.power
							
						end
						
					end
					
				end
				
				if power > 0 then
			
					table.insert(self.lines, {px, py, 800*math.sign(cx-px), math.sign(cx-px)*800*m+q})
				
				end
				
				
			else
			
				v = hit[1]
				
				table.insert(self.lines, {px, py, v.x+8, (v.x+8)*m+q})
				
				v.health = v.health - power
				
				table.sort(zombies, function(v1, v2)
					
					local dist1 = ((v1.x+8-v.x+8)^2+(v1.y+8-v.y+8)^2)^.5
					local dist2 = ((v2.x+8-v.x+8)^2+(v2.y+8-v.y+8)^2)^.5
				
					v1.dist = dist1; v2.dist = dist2
				
					return dist1<dist2
				end)
				
				for i, v in ipairs(zombies) do
				
					print(v.dist, self.weapon.explode.radius)
				
					if v.dist > self.weapon.explode.radius then
					
						break
						
					else
					
						v.health = v.health - self.weapon.explode.power
						
					end
					
				end
				
				table.insert(self.circles, {x = v.x, y = v.y, r = self.weapon.explode.radius})
				
				local rocket = {x = v.x, y = v.y}
				rocket.weapon = {power = self.weapon.explode.power/2, spread = math.pi, bullets = self.weapon.explode.fragments}
				rocket.lines = self.lines
				for i = 1, rocket.weapon.bullets do
					player.shoot(rocket, 100, 100)
				end
				
			end
		
			for i = #zombies, 1, -1 do
			
				if zombies[i].health <= 0 then
				
					table.remove(zombies, i)
					
				end
				
			end
			
			died = false
		
		else
		
			table.insert(self.lines, {px, py, 800*math.sign(cx-px), math.sign(cx-px)*800*m+q})
			
		end
	
	end


	
player.update = function(self, dt)

	local x, y = love.mouse.getPosition()
	
	local angle = math.atan2(self.y-y, self.x-x)-math.pi/2
	
	local sin, cos = math.sin(angle), -math.cos(angle)
	
	if self.move then
	
		self.x = self.x + self.speed*sin*dt
		
		self.y = self.y + self.speed*cos*dt
		
	end

	for i, v in ipairs(zombies) do
	
		if player:collides(v) then
		
			player.health = player.health - v.attack*25*dt
			
			break
			
		end
		
	end
	
	if self.weapon.autofire and love.mouse.isDown 'l' and self.cooldown == 0 then
	
		self.lines = {}
		self.circles = {}
	
		for i = 1, self.weapon.bullets do
			
			player:shoot(x, y)
			
		end
		
	end
	
	self.cooldown = math.max(self.cooldown-dt, 0)
	if self.cooldown == 0 then
	
		self.lines = nil
	
	end
	
end


player.draw = function(self)

	local x, y = love.mouse.getPosition()
	local px, py = self.x, self.y
	local angle = math.atan2(y-py, x-px)-(self.move and math.pi or 0)
	local x, y = 64*math.cos(angle), 64*math.sin(angle)

	love.graphics.setColor(self.health/1000*255, self.health/1000*255, 255)
	
	love.graphics.rectangle('fill', px-8, py-8, 16, 16)
	
	love.graphics.setColor(255,255,255, self.cooldown/self.weapon.cooldown*255)
	
	if self.lines then
	
		for i, line in ipairs(self.lines) do
		
			love.graphics.line(line)
		
		end
	
	end
	
	if self.circles then
	
		for i, circle in ipairs(self.circles) do
		
			love.graphics.circle('fill', circle.x, circle.y, circle.r, circle.r*2)
			
		end
		
	end
	
	love.graphics.setColor(255,255,255,160)
	
	love.graphics.line(px, py, x+px, y+py)
	
	love.graphics.setColor(255,255,255)
	
	love.graphics.print(self.weapon.name, 0, 0)
	love.graphics.print(love.timer.getFPS(), 0, 12)
	love.graphics.print(#zombies, 0, 24)

end



love.update = function(dt)

	zombies:update(dt)
	
	player:update(dt)

end


love.draw = function()

	zombies:draw()
	
	player:draw()
	
end


love.mousepressed = function(x, y, b)

	if b == 'r' then
	
		player.move = not player.move
		
	elseif b == 'l' and player.cooldown == 0 then
	
		local self = player
	
		self.lines = {}
		self.circles = {}
	
		for i = 1, self.weapon.bullets do
			
			player:shoot(x, y)
			
		end
		
	elseif b == 'm' then
	
		zombies.move = not zombies.move
		
	elseif b == 'wu' then
	
		zombies:spawnHorde(x, y, 10)
		
	elseif b == 'wd' then
	
		zombies:spawn(x-8, y-8)
		
	end
	
end


love.keypressed = function(k, u)

	if tonumber(k) and tonumber(k) <= #player.weapons.list then
	
		k = tonumber(k)
		
		player.weapon = player.weapons[player.weapons.list[k]]
		
	elseif k == 'kp+' then
	
		zombies:spawnHorde(200, 200, 15)
		
	end
	
end



--[=[
arrowArray = {
{0,0,0,1,1,0,0,0},
{0,0,0,0,0,1,0,0},
{0,0,0,0,0,0,1,0},
{1,1,1,1,1,1,1,1},
{1,1,1,1,1,1,1,1},
{0,0,0,0,0,0,1,0},
{0,0,0,0,0,1,0,0},
{0,0,0,1,1,0,0,0}}
]=]
