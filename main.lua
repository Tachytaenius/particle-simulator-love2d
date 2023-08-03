math.tau = math.pi * 2

local vec2 = require("lib.mathsies").vec2
local list = require("lib.list")

local particles
local spawnIfHoldingShift

-- Functions
local electricForce, personalSpaceForce
local newParticle

local function randCircle(r)
	return vec2.rotate(vec2(r, 0), love.math.random() * math.tau)
end

function love.load()
	particles = list()

	-- for _=1, 300 do
	-- 	newParticle(
	-- 		(love.math.random() > 0.5 and 1 or -1) and 0,
	-- 		1,
	-- 		vec2(love.math.random(), love.math.random()) * vec2(100) + vec2(300)
	-- 	)
	-- end

	newParticle(1, 1, vec2(300, 300))
	newParticle(-1, 1, vec2(300, 450))
end

function love.mousepressed()
	spawnIfHoldingShift = true
end

function love.update(dt)
	-- Add to simulation
	local brushRadius = 1
	if not love.keyboard.isDown("lshift") or spawnIfHoldingShift then
		if love.mouse.isDown(1) then
			newParticle(1, 1, vec2(love.mouse.getPosition()) + randCircle(brushRadius))
		end
		if love.mouse.isDown(2) then
			newParticle(-1, 1, vec2(love.mouse.getPosition()) + randCircle(brushRadius))
		end
		if love.mouse.isDown(3) then
			newParticle(0, 100, vec2(love.mouse.getPosition()) + randCircle(brushRadius))
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
				-- personalSpaceForce(particleA, particleB, dt)
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

function newParticle(charge, mass, pos)
	local particle = {}
	particle.position = pos
	particle.velocity = vec2()
	particle.charge = charge
	particle.mass = 1
	particle.colour = {particle.charge, 0.5, -particle.charge, 1}
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

	local force = -1 * electricForceStrength * particleA.charge * particleB.charge * math.min(1.0, distance ^ -1)
	if force ~= force then -- Distance is zero
		return
	end
	force = force * direction

	particleA.velocity = particleA.velocity + force / particleA.mass * dt
	particleB.velocity = particleB.velocity - force / particleB.mass * dt
end

function gravitationalForce(particleA, particleB, dt)
	local gravitationalForceStrength = 100

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
	local personalSpaceForceStrength = 200

	local difference = particleB.position - particleA.position
	local distance = #difference
	local direction
	if distance > 0 then
		direction = difference / distance
	else
		direction = vec2(0, 0)
	end

	local force = personalSpaceForceStrength * particleA.charge * particleB.charge * math.min(1.0, distance ^ -5)
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
	local force = strangeForceStrength * 1/(math.exp(distance-offset)+math.exp(-(distance-offset))) -- random bell shaped curve: sech
	force = force * direction

	particleA.velocity = particleA.velocity + force / particleA.mass * dt
	particleB.velocity = particleB.velocity - force / particleB.mass * dt
end
