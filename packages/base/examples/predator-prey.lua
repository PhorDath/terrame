-- @example Implementation of a spatial predator-prey model.
-- This model has two Societies. One composed by preys that
-- feed grass and the other composed by predators that feed
-- preys. Agents move randomly in space and can reproduce.
-- The output is similar to Lotka-Volterra equations.
-- @image predator-prey.bmp

Random{seed = 200}

predator = Agent{
	energy = 40,
	name = "predator",
	execute = function(self)
		forEachNeighbor(self:getCell(), function(cell, neigh)
			other = neigh:getAgent()
			if not other then return end

			if other.name == "prey" and Random():number() < 0.5 then
				self.energy = self.energy + other.energy / 5
				other:die()
				return false -- found a prey, stop forEachAgent
			end
		end)

		self.energy = self.energy - 4
		self:walk()
		if self.energy >= 50 then
			self.energy = self.energy / 2
			self:reproduce()
		elseif self.energy <= 0 then
			self:die()
		end
	end
}

prey = Agent{
	energy = 40,
	name = "prey",
	execute = function(self)
		if self:getCell().cover == "pasture" then
			self:getCell().cover = "soil"
			self.energy = self.energy + 20
		end

		self.energy = self.energy - 1
		self:walk()

		if self.energy >= 30 then
			neigh = self:getCell():getNeighborhood():sample()

			if neigh:isEmpty() then
				child = self:reproduce()
				child:move(neigh)
			end
		elseif self.energy <= 0 then
			self:die()
		end

	end
}

predators = Society{
	instance = predator,
	quantity = 20
}

preys = Society{
	instance = prey,
	quantity = 20
}

cell = Cell{
	init = function(cell)
		cell.cover = "pasture"
		cell.count = 0
	end,
	regrowth = function(cell)
		if cell.cover == "soil" then
			cell.count = cell.count + 1
			if cell.count >= 4 then
				cell.cover = "pasture"
				cell.count = 0
			end
		end
	end,
	owner = function(cell)
		local agent = cell:getAgent()

		if not agent then return "empty" end

		return agent.name
	end
}

cs = CellularSpace{
	xdim = 30,
	instance = cell
}

cs:createNeighborhood()

env = Environment{
	cs,
	predators,
	preys
}

env:createPlacement{max = 1}

c = Cell{
	predators = function() return #predators end,
	preys = function() return #preys end
}

chart = Chart{
	target = c,
	select = {"predators", "preys"},
	color = {"red", "blue"}
}

Map{
	target = cs,
	select = "cover",
	value = {"soil", "pasture"},
	color = {"brown", "green"}
}

Map{
	target = cs,
	select = "owner",
	value = {"empty", "predator", "prey"},
	color = {"white", "red", "blue"}
}


c:notify()

timer = Timer{
	Event{action = function()
		preys:execute()
		predators:execute()
		c:notify()
		cs:regrowth()
		cs:notify()
	end}
}

timer:execute(500)

