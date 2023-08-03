math.tau = math.pi * 2

local vec2 = require("lib.mathsies").vec2
local list = require("lib.list")

local particles
local spawnIfHoldingShift

-- Functions
local electricForce, personalSpaceForce, gravitationalForce, strangeForce
local newParticle

local function randCircle(r)
	return vec2.rotate(vec2(love.math.random() ^ 0.5 * r, 0), love.math.random() * math.tau)
end

function love.load()
	particles = list()

 	for _=1, 400 do
		local massive = love.math.random() > 0.75
		local pos = randCircle(200)
		newParticle(
			{
				electric = massive and 0 or love.math.random() > 0.5 and 1 or -1,
				strange = 0
			},
			massive and 1000 or 1,
			pos + vec2(300, 300),
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
					strange = 0
				},
			1, vec2(love.mouse.getPosition()) + randCircle(brushRadius))
		end
		if love.mouse.isDown(2) then
			newParticle(
				{
					electric = -1,
					strange = 0
				},
			1, vec2(love.mouse.getPosition()) + randCircle(brushRadius))
		end
		if love.mouse.isDown(3) then
				newParticle({
					electric = 0,
					strange = 0
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
				electricForce(particleA, particleB, dt)
				personalSpaceForce(particleA, particleB, dt)
				gravitationalForce(particleA, particleB, dt)
				strangeForce(particleA, particleB, dt)
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

function electricForce(particleA, particleB, dt)
	local electricForceStrength = 500

	local difference = particleB.position - particleA.position
	local distance = #difference
	local direction
	if distance > 0 then
		direction = difference / distance
	else
		direction = vec2(0, 0)
	end

	local force = -1 * electricForceStrength * particleA.charges.electric * particleB.charges.electric * math.min(1.0, distance ^ -1)
	if force ~= force then -- Distance is zero
		return
	end
	force = force * direction

	particleA.velocity = particleA.velocity + force / particleA.mass * dt
	particleB.velocity = particleB.velocity - force / particleB.mass * dt
end

function gravitationalForce(particleA, particleB, dt)
	local gravitationalForceStrength = 1

	local difference = particleB.position - particleA.position
	local distance = #difference
	local direction
	if distance > 0 then
		direction = difference / distance
	else
		direction = vec2(0, 0)
	end

	local force = gravitationalForceStrength * particleA.mass * particleB.mass * math.min(1.0, distance ^ -1)
	if force ~= force then -- Distance is zero
		return
	end
	force = force * direction

	particleA.velocity = particleA.velocity + force / particleA.mass * dt
	particleB.velocity = particleB.velocity - force / particleB.mass * dt
end

function personalSpaceForce(particleA, particleB, dt)
	local personalSpaceForceStrength = 2000

	local difference = particleB.position - particleA.position
	local distance = #difference
	local direction
	if distance > 0 then
		direction = difference / distance
	else
		direction = vec2(0, 0)
	end

	local velocityDifference = particleB.velocity - particleA.velocity
	local motionTowardsEachOther = vec2.dot(velocityDifference, -difference)
	local force = math.max(-1, -1 * personalSpaceForceStrength * distance ^ -5) * motionTowardsEachOther
	if force ~= force then -- Distance is zero
		return
	end
	force = force * direction

	particleA.velocity = particleA.velocity + force / particleA.mass * dt
	particleB.velocity = particleB.velocity - force / particleB.mass * dt
end

function strangeForce(particleA, particleB, dt)
	local strangeForceStrength = 10000

	local difference = particleB.position - particleA.position
	local distance = #difference
	local direction
	if distance > 0 then
		direction = difference / distance
	else
		direction = vec2(0, 0)
	end

	local offset = 100
	local force = strangeForceStrength * particleA.charges.strange * particleB.charges.strange * 1/(math.exp(distance-offset)+math.exp(-(distance-offset))) -- random bell shaped curve: sech
	force = force * direction

	particleA.velocity = particleA.velocity + force / particleA.mass * dt
	particleB.velocity = particleB.velocity - force / particleB.mass * dt
end
