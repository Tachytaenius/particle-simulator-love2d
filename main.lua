math.tau = math.pi * 2
function math.lerp(a, b, i)
	return a + i * (b - a)
end

local vec2 = require("lib.mathsies").vec2
local list = require("lib.list")

local particles
local spawnIfHoldingShift

-- Functions
local newParticle, absorbParticle

local function randCircle(r)
	return vec2.rotate(vec2(love.math.random() ^ 0.5 * r, 0), love.math.random() * math.tau)
end

--[[
	Charges:
	Electric: Real number
	Personal space: Positive real number
	Strange A: Real number
	Strange B: Real number
]]

function love.load()
	particles = list()

	for _=1, 100 do
		local pos = randCircle(300)
		newParticle(
			{
				electric = 0,
				personalSpace = 1,
				strangeA = 1,
				strangeB = 0
			},
			1,
			pos + vec2(500, 400),
			vec2(-pos.y, pos.x) * 0.05
		)
	end

	newParticle(
		{
			electric = 0,
			personalSpace = 1,
			strangeA = 1,
			strangeB = 0
		},
		1,
		vec2(300, 300),
		vec2()
	)

	newParticle(
		{
			electric = 0,
			personalSpace = 1,
			strangeA = 1,
			strangeB = 0
		},
		1,
		vec2(500, 300),
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
					strangeA = 0,
					strangeB = 0
				},
			1, vec2(love.mouse.getPosition()) + randCircle(brushRadius))
		end
		if love.mouse.isDown(2) then
			newParticle(
				{
					electric = -1,
					personalSpace = 0,
					strangeA = 0,
					strangeB = 0
				},
			1, vec2(love.mouse.getPosition()) + randCircle(brushRadius))
		end
		if love.mouse.isDown(3) then
				newParticle({
					electric = 0,
					personalSpace = 1,
					strangeA = 0,
					strangeB = 0
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

		local particlesToSpawn = {}
		local particlesToDelete = {}
		function absorbParticle(absorber, absorbee)
			absorbee.ignore = true
			particlesToDelete[#particlesToDelete + 1] = absorbee

			absorber.charges.electric = absorber.charges.electric + absorbee.charges.electric
			absorber.charges.strangeA = absorber.charges.strangeA + absorbee.charges.strangeB
			absorber.charges.strangeB = absorber.charges.strangeB + absorbee.charges.strangeA -- What are the implications of this?

			local i = absorbee.mass / (absorber.mass + absorbee.mass)
			absorber.position = math.lerp(absorber.position, absorbee.position, i)
			absorber.velocity = absorber.velocity + absorbee.velocity
			absorber.mass = absorber.mass + absorbee.mass
		end
		for i = 1, particles.size - 1 do
			local particleA = particles:get(i)

			for j = i + 1, particles.size do
				local particleB = particles:get(j)

				if not particleA.ignore and not particleB.ignore then
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

						-- Strange "force" emission
						local strangeForceBaseEmissionChancePerSecond = 0.1
						local strangeForceEmittedSlowness = 10
						if particleA.charges.strangeA ~= 0 and particleB.charges.strangeA ~= 0 then -- TODO: Replace with multiplication?
							local strangeForceBaseEmissionChanceThisTick = 1 - (1 - strangeForceBaseEmissionChancePerSecond) ^ dt
							local function tryEmitAToB()
								if particleA.charges.strangeA ~= 0 and love.math.random() < strangeForceBaseEmissionChanceThisTick then
									particlesToSpawn[#particlesToSpawn + 1] = {
										{
											electric = 0,
											personalSpace = 0,
											strangeA = 0,
											strangeB = particleA.charges.strangeA
										},
										0,
										particleA.position,
										particleA.velocity + direction * distance / strangeForceEmittedSlowness
									}
									particleA.charges.strangeA = 0
									particleA.velocity = particleA.velocity - direction * distance / strangeForceEmittedSlowness
								end
							end
							local function tryEmitBToA()
								if particleB.charges.strangeA ~= 0 and love.math.random() < strangeForceBaseEmissionChanceThisTick then
									particlesToSpawn[#particlesToSpawn + 1] = {
										{
											electric = 0,
											personalSpace = 0,
											strangeA = 0,
											strangeB = particleB.charges.strangeA
										},
										0,
										particleB.position,
										particleB.velocity - direction * distance / strangeForceEmittedSlowness
									}
									particleB.charges.strangeA = 0
									particleB.velocity = particleB.velocity + direction * distance / strangeForceEmittedSlowness
								end
							end
							if love.math.random() < 0.5 then
								tryEmitAToB()
								tryEmitBToA()
							else
								tryEmitBToA()
								tryEmitAToB()
							end
						end

						force = force * direction
						if particleA.mass ~= 0 then
							particleA.velocity = particleA.velocity + force / particleA.mass * dt
						end
						if particleB.mass ~= 0 then
							particleB.velocity = particleB.velocity - force / particleB.mass * dt
						end
					end
					-- Strange "force" absorbtion
					local strangeForceBaseAbsorptionChancePerSecond = 0.2
					local function tryAAbsorbB()
						if particleB.charges.strangeB ~= 0 then
							local distFactor
							if distance > 0 then
								distFactor = math.min(1, distance ^ -0.0001)
							else
								distFactor = 1
							end
							local absorptionChancePerSecond = strangeForceBaseAbsorptionChancePerSecond * distFactor
							local absorptionChanceThisTick = 1 - (1 - absorptionChancePerSecond) ^ dt
							if love.math.random() < absorptionChanceThisTick then
								absorbParticle(particleA, particleB)
							end
						end
					end
					tryAAbsorbB()
				end
			end
		end
		for _, particle in ipairs(particlesToDelete) do
			particles:remove(particle)
		end
		for _, newParticleParameters in ipairs(particlesToSpawn) do
			newParticle(unpack(newParticleParameters))
		end
	end
end

function love.draw()
	love.graphics.setPointSize(3)
	for i = 1, particles.size do
		local particle = particles:get(i)
		love.graphics.setColor(particle.charges.strangeA / 2 + 0.5, particle.charges.strangeB / 2 + 0.5, 0.5)
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
