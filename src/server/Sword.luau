-- Sword.luau - Sword Tool Creator (Server)

local Sword = {}

local DAMAGE = 25
local COOLDOWN = 1

function Sword.create()
	local tool = Instance.new("Tool")
	tool.Name = "Sword"
	tool.RequiresHandle = true
	tool.CanBeDropped = true
	
	-- Handle
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1, 4, 1)
	handle.BrickColor = BrickColor.new("Dark stone grey")
	handle.Material = Enum.Material.Metal
	handle.Parent = tool
	
	-- Mesh für Schwert-Optik
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.Scale = Vector3.new(0.5, 2, 0.5)
	mesh.MeshId = "rbxassetid://4748589085" -- Schwert-Mesh
	mesh.TextureId = ""
	mesh.Parent = handle
	
	-- Hitbox für Treffererkennung
	local hitbox = Instance.new("Part")
	hitbox.Name = "Hitbox"
	hitbox.Size = Vector3.new(4, 2, 1)
	hitbox.Transparency = 1
	hitbox.CanCollide = false
	hitbox.Massless = true
	hitbox.Parent = tool
	
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = hitbox
	weld.Parent = handle
	
	-- Cooldown
	local canAttack = true
	
	tool.Activated:Connect(function()
		if not canAttack then return end
		
		local character = tool.Parent
		if not character then return end
		
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local root = character:FindFirstChild("HumanoidRootPart")
		if not humanoid or not root then return end
		
		-- Hitbox vor dem Spieler positionieren
		hitbox.CFrame = root.CFrame * CFrame.new(0, 0, -3)
		
		-- Raycast für Treffer
		local rayOrigin = root.Position
		local rayDirection = (root.CFrame.LookVector * -1) * 4
		local params = RaycastParams.new()
		params.FilterDescendantsInstances = {character}
		params.FilterType = Enum.RaycastFilterType.Exclude
		
		local result = workspace:Raycast(rayOrigin, rayDirection, params)
		if result then
			local hitModel = result.Instance and result.Instance.Parent
			if hitModel then
				local humanoid = hitModel:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.Health > 0 then
					local tags = hitModel:FindFirstChild("Tags")
					if tags and tags:FindFirstChild("IsEnemy") then
						humanoid:TakeDamage(DAMAGE)
						print("Gegner getroffen! -" .. DAMAGE .. " HP")
					end
				end
			end
		end
		
		-- Cooldown
		canAttack = false
		task.delay(COOLDOWN, function()
			canAttack = true
		end)
	end)
	
	tool.Parent = game:GetService("StarterPack")
	return tool
end

function Sword.setupStarterPack()
	-- Ensure sword exists in StarterPack
	local starterPack = game:GetService("StarterPack")
	local existing = starterPack:FindFirstChild("Sword")
	if not existing then
		Sword.create()
		print("Sword created in StarterPack")
	end
end

return Sword
