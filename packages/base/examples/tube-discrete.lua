-- @example A model that describes water flowing out of a tube. It uses
-- an observation step more frequent than the execution. Because of that,
-- we can see that the water flows out of the tube in discrete steps.
-- @image tube-discrete.png

world = Cell{
	water = 40,
	execute = function(world)
        world.water = world.water - 5
	end
}

chart = Chart{
    target = world,
	yLabel = "Gallons",
}

t = Timer{
    Event{action = world},
    Event{period = 0.25, action = chart}
}

t:run(8)

