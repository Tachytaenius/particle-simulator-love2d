math.tau = math.pi * 2

local vec2 = require("lib.mathsies").vec2
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
]]

function love.load()
	particles = list()

	for _=1, 500 do
		local massive = love.math.random() > 0.25
		local pos = randCircle(100)
		newParticle(
			{
				electric = massive and 0 or love.math.random() > 0.5 and 1 or -1,
				personalSpace = massive and 1 or 0
			},
			massive and 1000 or 1,
			pos + vec2(500, 400),
			vec2(-pos.y, pos.x) * 0.05
		)
	end
end

function love.mousepressed()
	spawnIfHoldingShift = true
end

function love.update(dt)
	-- Add to simulation
	local brushRadius = 1
	if not love.keyboard.isDown("lshift") or spawnIfHoldingShift then
		if love.mouse.isDown(1) then
			newParticle(
				{
					electric = 1,
					personalSpace = 0
				},
			1, vec2(love.mouse.getPosition()) + randCircle(brushRadius))
		end
		if love.mouse.isDown(2) then
			newParticle(
				{
					electric = -1,
					personalSpace = 0
				},
			1, vec2(love.mouse.getPosition()) + randCircle(brushRadius))
		end
		if love.mouse.isDown(3) then
				newParticle({
					electric = 0,
					personalSpace = 1
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
					local personalSpaceForceStrength = 2000
					force = force + -1 * personalSpaceForceStrength * particleA.charges.personalSpace * particleB.charges.personalSpace * math.min(1.0, distance ^ -4)
						* particleA.mass * particleB.mass * math.min(1, math.max(0, -vec2.dot(difference, particleB.velocity - particleA.velocity)))

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
		love.graphics.setColor(particle.colour)
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
