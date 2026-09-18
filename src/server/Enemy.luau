-- Enemy.luau - NPC Enemy AI with Proper Model (Server)

local Enemy = {}

local ENEMY_NAME = "Enemy"
local ENEMY_MAX_HEALTH = 100
local ENEMY_DAMAGE = 10
local ATTACK_RANGE = 6
local ATTACK_COOLDOWN = 2
local WALK_SPEED = 12

local function createEnemyModel(position: Vector3)
	local enemy = Instance.new("Model")
	enemy.Name = "Enemy"
	
	-- HumanoidRootPart (RootPart)
	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Size = Vector3.new(2, 2, 1)
	rootPart.Position = position
	rootPart.Anchored = false
	rootPart.CanCollide = true
	rootPart.Material = Enum.Material.ForceField
	rootPart.Transparency = 1
	rootPart.Parent = enemy
	
	-- Humanoid
	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = 100
	humanoid.Health = 100
	humanoid.WalkSpeed = 12
	humanoid.Parent = enemy
	
	-- Torso
	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2, 1)
	torso.Position = Vector3.new(0, 1, 0)
	torso.Anchored = false
	torso.CanCollide = true
	torso.Parent = enemy
	
	local torsoWeld = Instance.new("WeldConstraint")
	torsoWeld.Part0 = enemy:FindFirstChild("HumanoidRootPart")
	torsoWeld.Part1 = torso
	torsoWeld.Parent = torso
	
	-- Head
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(2, 1, 1)
	head.Position = Vector3.new(0, 2.5, 0)
	head.Anchored = false
	head.CanCollide = true
	head.Parent = enemy
	
	local neck = Instance.new("WeldConstraint")
	neck.Part0 = enemy:FindFirstChild("Torso")
	neck.Part1 = head
	neck.Parent = head
	
	-- Left Arm
	local leftArm = Instance.new("Part")
	leftArm.Name = "Left Arm"
	leftArm.Size = Vector3.new(1, 2, 1)
	leftArm.Position = Vector3.new(-1.5, 1, 0)
	leftArm.Anchored = false
	leftArm.CanCollide = true
	leftArm.Parent = enemy
	
	local leftArmWeld = Instance.new("WeldConstraint")
	leftArmWeld.Part0 = enemy:FindFirstChild("Torso")
	leftArmWeld.Part1 = leftArm
	leftArmWeld.Parent = leftArm
	
	-- Right Arm
	local rightArm = Instance.new("Part")
	rightArm.Name = "Right Arm"
	rightArm.Size = Vector3.new(1, 2, 1)
	rightArm.Position = Vector3.new(1.5, 1, 0)
	rightArm.Anchored = false
	rightArm.CanCollide = true
	rightArm.Parent = enemy
	
	local rightArmWeld = Instance.new("WeldConstraint")
	rightArmWeld.Part0 = enemy:FindFirstChild("Torso")
	rightArmWeld.Part1 = rightArm
	rightArmWeld.Parent = rightArm
	
	-- Left Leg
	local leftLeg = Instance.new("Part")
	leftLeg.Name = "Left Leg"
	leftLeg.Size = Vector3.new(1, 2, 1)
	leftLeg.Position = Vector3.new(-0.5, -1.5, 0)
	leftLeg.Anchored = false
	leftLeg.CanCollide = true
	leftLeg.Parent = enemy
	
	local leftLegWeld = Instance.new("WeldConstraint")
	leftLegWeld.Part0 = enemy:FindFirstChild("Torso")
	leftLegWeld.Part1 = leftLeg
	leftLegWeld.Parent = leftLeg
	
	-- Right Leg
	local rightLeg = Instance.new("Part")
	rightLeg.Name = "Right Leg"
	rightLeg.Size = Vector3.new(1, 2, 1)
	rightLeg.Position = Vector3.new(0.5, -1.5, 0)
	rightLeg.Anchored = false
	rightLeg.CanCollide = true
	rightLeg.Parent = enemy
	
	local rightLegWeld = Instance.new("WeldConstraint")
	rightLegWeld.Part0 = enemy:FindFirstChild("Torso")
	rightLegWeld.Part1 = rightLeg
	rightLegWeld.Parent = rightLeg
	
	-- Set PrimaryPart
	enemy.PrimaryPart = enemy:FindFirstChild("HumanoidRootPart")
	
	-- Tags for sword detection
	local tags = Instance.new("Folder")
	tags.Name = "Tags"
	tags.Parent = enemy
	
	local isEnemyTag = Instance.new("StringValue")
	isEnemyTag.Name = "IsEnemy"
	isEnemyTag.Value = "true"
	isEnemyTag.Parent = tags
	
	return enemy
end

function Enemy.create(position: Vector3)
	local enemy = Instance.new("Model")
	enemy.Name = "Enemy"
	
	-- HumanoidRootPart
	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Size = Vector3.new(2, 2, 1)
	rootPart.Position = position
	rootPart.Anchored = false
	rootPart.CanCollide = true
	rootPart.Parent = enemy
	
	-- Humanoid
	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = 100
	humanoid.Health = 100
	humanoid.WalkSpeed = 12
	humanoid.Parent = enemy
	
	-- Torso
	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2, 1)
	torso.Position = Vector3.new(0, 1, 0)
	torso.Anchored = false
	torso.CanCollide = true
	torso.Parent = enemy
	
	local torsoWeld = Instance.new("WeldConstraint")
	torsoWeld.Part0 = enemy:FindFirstChild("HumanoidRootPart")
	torsoWeld.Part1 = torso
	torsoWeld.Parent = torso
	
	-- Head
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(2, 1, 1)
	head.Position = Vector3.new(0, 2.5, 0)
	head.Anchored = false
	head.CanCollide = true
	head.Parent = enemy
	
	local neck = Instance.new("WeldConstraint")
	neck.Part0 = enemy:FindFirstChild("Torso")
	neck.Part1 = head
	neck.Parent = head
	
	-- Left Arm
	local leftArm = Instance.new("Part")
	leftArm.Name = "Left Arm"
	leftArm.Size = Vector3.new(1, 2, 1)
	leftArm.Position = Vector3.new(-1.5, 1, 0)
	leftArm.Anchored = false
	leftArm.CanCollide = true
	leftArm.Parent = enemy
	
	local leftArmWeld = Instance.new("WeldConstraint")
	leftArmWeld.Part0 = enemy:FindFirstChild("Torso")
	leftArmWeld.Part1 = leftArm
	leftArmWeld.Parent = leftArm
	
	-- Right Arm
	local rightArm = Instance.new("Part")
	rightArm.Name = "Right Arm"
	rightArm.Size = Vector3.new(1, 2, 1)
	rightArm.Position = Vector3.new(1.5, 1, 0)
	rightArm.Anchored = false
	rightArm.CanCollide = true
	rightArm.Parent = enemy
	
	local rightArmWeld = Instance.new("WeldConstraint")
	rightArmWeld.Part0 = enemy:FindFirstChild("Torso")
	rightArmWeld.Part1 = rightArm
	rightArmWeld.Parent = rightArm
	
	-- Left Leg
	local leftLeg = Instance.new("Part")
	leftLeg.Name = "Left Leg"
	leftLeg.Size = Vector3.new(1, 2, 1)
	leftLeg.Position = Vector3.new(-0.5, -1.5, 0)
	leftLeg.Anchored = false
	leftLeg.CanCollide = true
	leftLeg.Parent = enemy
	
	local leftLegWeld = Instance.new("WeldConstraint")
	leftLegWeld.Part0 = enemy:FindFirstChild("Torso")
	leftLegWeld.Part1 = leftLeg
	leftLegWeld.Parent = leftLeg
	
	-- Right Leg
	local rightLeg = Instance.new("Part")
	rightLeg.Name = "Right Leg"
	rightLeg.Size = Vector3.new(1, 2, 1)
	rightLeg.Position = Vector3.new(0.5, -1.5, 0)
	rightLeg.Anchored = false
	rightLeg.CanCollide = true
	rightLeg.Parent = enemy
	
	local rightLegWeld = Instance.new("WeldConstraint")
	rightLegWeld.Part0 = enemy:FindFirstChild("Torso")
	rightLegWeld.Part1 = rightLeg
	rightLegWeld.Parent = rightLeg
	
	-- Set PrimaryPart
	enemy.PrimaryPart = enemy:FindFirstChild("HumanoidRootPart")
	
	-- Tags for sword detection
	local tags = Instance.new("Folder")
	tags.Name = "Tags"
	tags.Parent = enemy
	
	local isEnemyTag = Instance.new("StringValue")
	isEnemyTag.Name = "IsEnemy"
	isEnemyTag.Value = "true"
	isEnemyTag.Parent = tags
	
	-- Humanoid
	local humanoid = enemy:FindFirstChild("Humanoid")
	humanoid.MaxHealth = 100
	humanoid.Health = 100
	humanoid.WalkSpeed = 12
	
	-- Enemy AI
	task.spawn(function()
		while humanoid.Health > 0 do
			local target = nil
			for _, player in pairs(game.Players:GetPlayers()) do
				if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
					target = player.Character
					break
				end
			end
			
			if target then
				local targetRoot = target:FindFirstChild("HumanoidRootPart")
				local rootPart = enemy:FindFirstChild("HumanoidRootPart")
				if targetRoot and rootPart then
					local distance = (rootPart.Position - targetRoot.Position).Magnitude
					
					if distance <= 6 then
						-- Attack
						local targetHumanoid = target:FindFirstChild("Humanoid")
						if targetHumanoid then
							targetHumanoid:TakeDamage(10)
						end
						task.wait(2)
					else
						-- Move to player
						local humanoid = enemy:FindFirstChild("Humanoid")
						if humanoid then
							humanoid:MoveTo(targetRoot.Position)
						end
					end
				end
			end
			task.wait(0.2)
		end
	end)
	
	return enemy
end

function Enemy.spawnAt(position: Vector3)
	local enemy = Enemy.create(position)
	enemy.Parent = workspace
	return enemy
end

function Enemy.setupSpawning()
	-- Spawn initial enemy
	local enemy = Enemy.spawnAt(Vector3.new(0, 5, 20))
	print("Enemy spawned at spawn position")
	
	-- Respawn logic
	task.spawn(function()
		while true do
			task.wait(5)
			if not workspace:FindFirstChild("Enemy") then
				local newEnemy = Enemy.spawnAt(Vector3.new(0, 5, 20))
				print("Enemy respawned")
			end
		end
	end)
	
	print("Enemy spawning system initialized")
end

return Enemy
