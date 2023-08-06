math.tau = math.pi * 2

local vec2 = require("lib.mathsies").vec2
local vec3 = require("lib.mathsies").vec3
local list = require("lib.list")

local particles
local spawnIfHoldingShift

-- Functions
local newParticle

local function randCircle(r)
	return vec2.rotate(vec2(love.math.random() ^ 0.5 * r, 0), love.math.random() * math.tau)
end

--[[
	Charges:
	Electric: Real number
	Personal space: Positive real number
	Colour charge: vec3
]]

function love.load()
	particles = list()

	-- for _=1, 50 do
	-- 	local pos = randCircle(100)
	-- 	local colourSelector = love.math.random()
	-- 	local red, green, blue
	-- 	if colourSelector < 1/3 then
	-- 		red = true
	-- 	elseif colourSelector < 2/3 then
	-- 		green = true
	-- 	elseif colourSelector < 3/3 then
	-- 		blue = true
	-- 	end
	-- 	newParticle(
	-- 		{
	-- 			electric = 0,
	-- 			personalSpace = 1,
	-- 			colour = red and vec3(1, 0, 0) or green and vec3(0, 1, 0) or vec3(0, 0, 1)
	-- 		},
	-- 		1,
	-- 		pos + vec2(500, 400),
	-- 		vec2(-pos.y, pos.x) * 0.05
	-- 	)
	-- end

	newParticle(
		{
			electric = 0,
			personalSpace = 1,
			colour = vec3(1, 0, 0)
		},
		1,
		vec2(200, 200),
		vec2()
	)
	newParticle(
		{
			electric = 0,
			personalSpace = 1,
			colour = vec3(0, 1, 0)
		},
		1,
		vec2(300, 200),
		vec2()
	)
	newParticle(
		{
			electric = 0,
			personalSpace = 1,
			colour = vec3(0, 0, 1)
		},
		1,
		vec2(200, 300),
		vec2()
	)

	newParticle(
		{
			electric = 0,
			personalSpace = 1,
			colour = vec3(1, 0, 0)
		},
		1,
		vec2(800, 200),
		vec2()
	)
	newParticle(
		{
			electric = 0,
			personalSpace = 1,
			colour = vec3(0, 1, 0)
		},
		1,
		vec2(900, 200),
		vec2()
	)
	newParticle(
		{
			electric = 0,
			personalSpace = 1,
			colour = vec3(0, 0, 1)
		},
		1,
		vec2(800, 300),
		vec2()
	)
end

function love.mousepressed()
	spawnIfHoldingShift = true
end

function love.update(dt)
	-- Add to simulation
	local brushRadius = 15
	if not love.keyboard.isDown("lshift") or spawnIfHoldingShift then
		if love.mouse.isDown(1) then
			newParticle(
				{
					electric = 1,
					personalSpace = 0,
					colour = vec3()
				},
			1, vec2(love.mouse.getPosition()) + randCircle(brushRadius))
		end
		if love.mouse.isDown(2) then
			newParticle(
				{
					electric = -1,
					personalSpace = 0,
					colour = vec3()
				},
			1, vec2(love.mouse.getPosition()) + randCircle(brushRadius))
		end
		if love.mouse.isDown(3) then
				newParticle({
					electric = 0,
					personalSpace = 1,
					colour = vec3()
				},
			1000, vec2(love.mouse.getPosition()) + randCircle(brushRadius))
		end
	end
	spawnIfHoldingShift = false

	-- Simulate
	local timestepDivisions = 1
	for i = 1, timestepDivisions do
		local dt = dt / timestepDivisions
		for i = 1, particles.size do
			local particle = particles:get(i)
			particle.position = particle.position + particle.velocity * dt
		end
		for i = 1, particles.size - 1 do
			local particleA = particles:get(i)

			for j = i + 1, particles.size do
				local particleB = particles:get(j)

				local difference = particleB.position - particleA.position
				local distance = #difference
				if distance > 0 then
					local direction = difference / distance
					local force = 0

					-- Electric force
					local electricForceStrength = 500
					force = force + electricForceStrength * -1 * particleA.charges.electric * particleB.charges.electric * math.min(1, distance ^ -1)

					-- Gravity
					local gravitationalForceStrength = 1
					force = force + gravitationalForceStrength * particleA.mass * particleB.mass * math.min(1.0, distance ^ -1)

					-- Personal space force
					local personalSpaceForceStrength = 2000000 -- TEMP for visibility of "baryons": please replace with 2000 again
					force = force + -1 * personalSpaceForceStrength * particleA.charges.personalSpace * particleB.charges.personalSpace * math.min(1.0, distance ^ -4)
						* particleA.mass * particleB.mass * math.min(1, math.max(0, -vec2.dot(difference, particleB.velocity - particleA.velocity)))
					
					-- Charm force
					local charmForceStrength = 1000
					force = force + charmForceStrength * vec3.distance(particleA.charges.colour, particleB.charges.colour) * math.min(1, distance ^ -1)

					force = force * direction
					particleA.velocity = particleA.velocity + force / particleA.mass * dt
					particleB.velocity = particleB.velocity - force / particleB.mass * dt
				end
			end
		end
	end
end

function love.draw()
	love.graphics.setPointSize(2)
	for i = 1, particles.size do
		local particle = particles:get(i)
		local colourColour = particle.charges.colour / 2 + 0.5
		love.graphics.setColor(colourColour.x, colourColour.y, colourColour.z)
		love.graphics.points(particle.position.x, particle.position.y)
	end
end

function newParticle(charges, mass, pos, vel)
	local particle = {}
	particle.position = pos
	particle.velocity = vel or vec2()
	particle.charges = charges
	particle.mass = 1
	particle.colour = {particle.charges.electric, 0.5, -particle.charges.electric, 1}
	particles:add(particle)
end
