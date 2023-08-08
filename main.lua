math.tau = math.pi * 2

local vec2 = require("lib.mathsies").vec2
local list = require("lib.list")

local particles
local colourMode
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
	
	colourMode = "electricCharge"
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
			particle.feltForce = vec2()
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

					-- -- Electric force
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
					particleA.feltForce = particleA.feltForce + force
					particleB.feltForce = particleB.feltForce - force
				end
			end
		end
	end
end

local function hsv2rgb(h, s, v)
	if s == 0 then
		return v, v, v
	end
	local _h = h / 60
	local i = math.floor(_h)
	local f = _h - i
	local p = v * (1 - s)
	local q = v * (1 - f * s)
	local t = v * (1 - (1 - f) * s)
	if i == 0 then
		return v, t, p
	elseif i == 1 then
		return q, v, p
	elseif i == 2 then
		return p, v, t
	elseif i == 3 then
		return p, q, v
	elseif i == 4 then
		return t, p, v
	elseif i == 5 then
		return v, p, q
	end
end

function love.draw()
	love.graphics.setPointSize(2)
	for i = 1, particles.size do
		local particle = particles:get(i)
		if colourMode == "electricCharge" then
			love.graphics.setColor(particle.charges.electric, 0.5, -particle.charges.electric)
		elseif colourMode == "electricAndPersonalSpaceCharge" then
			love.graphics.setColor(particle.charges.electric * 0.5 + 0.5, particle.charges.personalSpace, 1)
		elseif colourMode == "hsv" then
			local angle = vec2.toAngle(particle.velocity) % math.tau
			local speed = #particle.velocity
			local hue = math.deg(angle)
			local saturation = math.min(1, math.abs(#particle.feltForce) / 10)
			local value = math.min(1, speed / 10)
			love.graphics.setColor(hsv2rgb(hue, saturation, value))
		end
		love.graphics.points(particle.position.x, particle.position.y)
	end
end

function newParticle(charges, mass, pos, vel)
	local particle = {}
	particle.position = pos
	particle.velocity = vel or vec2()
	particle.charges = charges
	particle.mass = 1
	particles:add(particle)
end
