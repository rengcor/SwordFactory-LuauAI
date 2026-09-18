local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local SWORD_NAME = "Sword"
local SWORD_HIT_EVENT_NAME = "SwordHitEvent"
local SWORD_PICKED_UP_EVENT_NAME = "SwordPickedUpEvent"
local CONNECTED_MARKER = "SwordClientConnected"

local player = Players.LocalPlayer
local swordHitEvent = ReplicatedStorage:WaitForChild(SWORD_HIT_EVENT_NAME)
local swordPickedUpEvent = ReplicatedStorage:WaitForChild(SWORD_PICKED_UP_EVENT_NAME)
local factoryEvent = ReplicatedStorage:WaitForChild("FactoryEvent")
local enchanterGuiFunc = ReplicatedStorage:WaitForChild("EnchanterGuiFunc")

-- ===== HUD (oben mittig) =====
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FactoryHud"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.fromOffset(520, 52)
topBar.Position = UDim2.new(0.5, -260, 0, 36)
topBar.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
topBar.BackgroundTransparency = 0.25
topBar.BorderSizePixel = 0
topBar.Parent = screenGui

local topBarCorner = Instance.new("UICorner")
topBarCorner.CornerRadius = UDim.new(0, 10)
topBarCorner.Parent = topBar

local topBarStroke = Instance.new("UIStroke")
topBarStroke.Color = Color3.fromRGB(255, 205, 60)
topBarStroke.Thickness = 2
topBarStroke.Parent = topBar

-- Gold (links)
local goldLabel = Instance.new("TextLabel")
goldLabel.Name = "GoldLabel"
goldLabel.Size = UDim2.fromOffset(150, 40)
goldLabel.Position = UDim2.fromOffset(8, 0)
goldLabel.BackgroundTransparency = 1
goldLabel.Text = "💰 50 Gold"
goldLabel.TextColor3 = Color3.fromRGB(255, 230, 100)
goldLabel.TextScaled = true
goldLabel.Font = Enum.Font.GothamBold
goldLabel.TextXAlignment = Enum.TextXAlignment.Left
goldLabel.Parent = topBar

-- Rang (Mitte)
local rankLabel = Instance.new("TextLabel")
rankLabel.Name = "RankLabel"
rankLabel.Size = UDim2.fromOffset(140, 40)
rankLabel.Position = UDim2.new(0.5, -70, 0, 0)
rankLabel.BackgroundTransparency = 1
rankLabel.Text = "⚔️ Schwertling"
rankLabel.TextColor3 = Color3.fromRGB(200, 210, 255)
rankLabel.TextScaled = true
rankLabel.Font = Enum.Font.GothamBold
rankLabel.Parent = topBar

-- Bank (rechts)
local bankLabel = Instance.new("TextLabel")
bankLabel.Name = "BankLabel"
bankLabel.Size = UDim2.fromOffset(150, 40)
bankLabel.Position = UDim2.new(1, -158, 0, 0)
bankLabel.BackgroundTransparency = 1
bankLabel.Text = "🏦 0/5"
bankLabel.TextColor3 = Color3.fromRGB(180, 255, 180)
bankLabel.TextScaled = true
bankLabel.Font = Enum.Font.GothamBold
bankLabel.TextXAlignment = Enum.TextXAlignment.Right
bankLabel.Parent = topBar

-- Fortschrittsbalken (Rang)
local progressTrack = Instance.new("Frame")
progressTrack.Name = "ProgressTrack"
progressTrack.Size = UDim2.fromOffset(484, 8)
progressTrack.Position = UDim2.fromOffset(8, 44)
progressTrack.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
progressTrack.BorderSizePixel = 0
progressTrack.Parent = topBar

local progressTrackCorner = Instance.new("UICorner")
progressTrackCorner.CornerRadius = UDim.new(0, 4)
progressTrackCorner.Parent = progressTrack

local progressFill = Instance.new("Frame")
progressFill.Name = "ProgressFill"
progressFill.Size = UDim2.fromScale(0, 1)
progressFill.Position = UDim2.fromOffset(0, 0)
progressFill.BackgroundColor3 = Color3.fromRGB(255, 205, 60)
progressFill.BorderSizePixel = 0
progressFill.Parent = progressTrack

-- ===== Toast =====
local toast = Instance.new("TextLabel")
toast.Name = "Toast"
toast.Size = UDim2.fromOffset(420, 44)
toast.Position = UDim2.new(0.5, -210, 0, 96)
toast.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
toast.BackgroundTransparency = 0.25
toast.Text = ""
toast.TextColor3 = Color3.fromRGB(255, 230, 100)
toast.TextScaled = true
toast.Font = Enum.Font.GothamBold
toast.Visible = false
toast.Parent = screenGui

local toastCorner = Instance.new("UICorner")
toastCorner.CornerRadius = UDim.new(0, 10)
toastCorner.Parent = toast

local toastStroke = Instance.new("UIStroke")
toastStroke.Color = Color3.fromRGB(255, 205, 60)
toastStroke.Thickness = 2
toastStroke.Parent = toast

local function showToast(text)
	toast.Text = text
	toast.Visible = true
	task.delay(3, function()
		toast.Text = ""
		toast.Visible = false
	end)
end

-- ===== Verzauberer-Upgrade-GUI =====
local enchanterGui = Instance.new("ScreenGui")
enchanterGui.Name = "EnchanterGui"
enchanterGui.ResetOnSpawn = false
enchanterGui.Enabled = false
enchanterGui.Parent = PlayerGui

local egWindow = Instance.new("Frame")
egWindow.Name = "Window"
egWindow.Size = UDim2.fromOffset(540, 390)
egWindow.Position = UDim2.new(0.5, -270, 0.5, -195)
egWindow.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
egWindow.BorderSizePixel = 0
egWindow.Parent = enchanterGui

local egCorner = Instance.new("UICorner")
egCorner.CornerRadius = UDim.new(0, 14)
egCorner.Parent = egWindow

local egStroke = Instance.new("UIStroke")
egStroke.Color = Color3.fromRGB(160, 90, 255)
egStroke.Thickness = 2
egStroke.Parent = egWindow

local egTitle = Instance.new("TextLabel")
egTitle.Size = UDim2.new(1, 0, 0, 46)
egTitle.Position = UDim2.fromOffset(0, 0)
egTitle.BackgroundTransparency = 1
egTitle.Text = "✨ Verzauberer-Upgrades"
egTitle.TextColor3 = Color3.fromRGB(220, 160, 255)
egTitle.TextScaled = true
egTitle.Font = Enum.Font.GothamBold
egTitle.Parent = egWindow

local egDivider = Instance.new("Frame")
egDivider.Size = UDim2.new(1, -24, 0, 2)
egDivider.Position = UDim2.fromOffset(12, 48)
egDivider.BackgroundColor3 = Color3.fromRGB(100, 60, 160)
egDivider.BorderSizePixel = 0
egDivider.Parent = egWindow

local egList = Instance.new("Frame")
egList.Name = "RowList"
egList.Size = UDim2.new(1, -24, 0, 260)
egList.Position = UDim2.fromOffset(12, 58)
egList.BackgroundTransparency = 1
egList.Parent = egWindow

local egListLayout = Instance.new("UIListLayout")
egListLayout.SortOrder = Enum.SortOrder.LayoutOrder
egListLayout.Padding = UDim.new(0, 6)
egListLayout.Parent = egList

local egClose = Instance.new("TextButton")
egClose.Name = "CloseBtn"
egClose.Size = UDim2.fromOffset(140, 40)
egClose.Position = UDim2.new(0.5, -70, 1, -52)
egClose.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
egClose.BorderSizePixel = 0
egClose.Text = "✖ Schliessen"
egClose.TextColor3 = Color3.fromRGB(255, 220, 220)
egClose.TextScaled = true
egClose.Font = Enum.Font.GothamBold
egClose.Parent = egWindow

local egCloseCorner = Instance.new("UICorner")
egCloseCorner.CornerRadius = UDim.new(0, 8)
egCloseCorner.Parent = egClose

egClose.MouseButton1Click:Connect(function()
	enchanterGui.Enabled = false
end)

local rowFrames = {}

local function refreshEnchanterGui(guiData)
	for _, f in ipairs(rowFrames) do
		f:Destroy()
	end
	rowFrames = {}

	for i, row in ipairs(guiData.rows) do
		local rowColor = Color3.fromRGB(row.colorR, row.colorG, row.colorB)

		local rowFrame = Instance.new("Frame")
		rowFrame.Name = "Row" .. i
		rowFrame.Size = UDim2.new(1, 0, 0, 46)
		rowFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
		rowFrame.BorderSizePixel = 0
		rowFrame.LayoutOrder = i
		rowFrame.Parent = egList
		table.insert(rowFrames, rowFrame)

		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 8)
		rowCorner.Parent = rowFrame

		local stripe = Instance.new("Frame")
		stripe.Size = UDim2.new(0, 5, 1, 0)
		stripe.BackgroundColor3 = rowColor
		stripe.BorderSizePixel = 0
		stripe.Parent = rowFrame

		local stripeCorner = Instance.new("UICorner")
		stripeCorner.CornerRadius = UDim.new(0, 8)
		stripeCorner.Parent = stripe

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.fromOffset(140, 46)
		nameLabel.Position = UDim2.fromOffset(12, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = row.name
		nameLabel.TextColor3 = rowColor
		nameLabel.TextScaled = true
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = rowFrame

		local chanceLabel = Instance.new("TextLabel")
		chanceLabel.Name = "ChanceLabel"
		chanceLabel.Size = UDim2.fromOffset(80, 46)
		chanceLabel.Position = UDim2.fromOffset(158, 0)
		chanceLabel.BackgroundTransparency = 1
		chanceLabel.Text = row.chancePercent .. "%"
		chanceLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
		chanceLabel.TextScaled = true
		chanceLabel.Font = Enum.Font.Gotham
		chanceLabel.Parent = rowFrame

		local plusBtn = Instance.new("TextButton")
		plusBtn.Name = "PlusBtn"
		plusBtn.Size = UDim2.fromOffset(44, 34)
		plusBtn.Position = UDim2.fromOffset(248, 6)
		plusBtn.BackgroundColor3 = row.maxed and Color3.fromRGB(60, 60, 60) or Color3.fromRGB(50, 180, 80)
		plusBtn.BorderSizePixel = 0
		plusBtn.Text = row.maxed and "MAX" or "+"
		plusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		plusBtn.TextScaled = true
		plusBtn.Font = Enum.Font.GothamBold
		plusBtn.AutoButtonColor = not row.maxed
		plusBtn.Parent = rowFrame

		local plusCorner = Instance.new("UICorner")
		plusCorner.CornerRadius = UDim.new(0, 6)
		plusCorner.Parent = plusBtn

		local priceLabel = Instance.new("TextLabel")
		priceLabel.Name = "PriceLabel"
		priceLabel.Size = UDim2.fromOffset(170, 46)
		priceLabel.Position = UDim2.fromOffset(300, 0)
		priceLabel.BackgroundTransparency = 1
		local priceText
		if row.maxed and row.nextCost == -1 and row.level == 0 then
			priceText = "Hoechste Raritaet"
		elseif row.maxed then
			priceText = "Voll ausgebaut"
		else
			priceText = "💰 " .. tostring(row.nextCost) .. " Gold"
		end
		priceLabel.Text = priceText
		priceLabel.TextColor3 = Color3.fromRGB(255, 210, 80)
		priceLabel.TextScaled = true
		priceLabel.Font = Enum.Font.Gotham
		priceLabel.TextXAlignment = Enum.TextXAlignment.Left
		priceLabel.Parent = rowFrame

		if not row.maxed then
			local capturedIndex = i
			plusBtn.MouseButton1Click:Connect(function()
				local result = enchanterGuiFunc:InvokeServer({ action = "buy", rarityIndex = capturedIndex })
				if result then
					if result.ok and result.guiData then
						refreshEnchanterGui(result.guiData)
					elseif result.message then
						showToast(result.message)
					end
				end
			end)
		end
	end
end

local function openEnchanterGui()
	enchanterGui.Enabled = true
	local guiData = enchanterGuiFunc:InvokeServer({ action = "getState" })
	if guiData then
		refreshEnchanterGui(guiData)
	end
end

-- ===== Verzauberer-Effekt =====
-- Strahl aus dem Maschineninneren (Y=7.5, Unterkante Maschinenkopf).
-- enchantStart  -> Strahl einblenden, Partikel laufen
-- enchantEnd    -> Burst + Strahl ausblenden
local ENCHANT_MACHINE_Y = 7.5 -- Unterkante Maschinenkopf (Energiepunkte im Tor)
local ENCHANT_X = 120
local ENCHANT_Z = 6

local BEAM_COLOR = Color3.fromRGB(180, 60, 255)
local BEAM_WHITE = Color3.fromRGB(255, 255, 255)
local LIGHT_COLOR = Color3.fromRGB(200, 80, 255)

-- Laufender Effekt (nur einer gleichzeitig)
local activeEnchantFx = nil

local function stopEnchantBeam(success: boolean)
	local fx = activeEnchantFx
	if not fx then
		return
	end
	activeEnchantFx = nil

	local burstColor = success and Color3.fromRGB(255, 180, 255) or Color3.fromRGB(150, 160, 220)
	local burstCount = success and 50 or 20
	local peakBright = success and 16 or 6

	-- Partikel-Burst beim Ergebnis
	fx.emitter.Color = ColorSequence.new(burstColor)
	fx.emitter:Emit(burstCount)

	-- Licht-Peak
	TweenService:Create(fx.light, TweenInfo.new(0.08), { Brightness = peakBright }):Play()

	task.spawn(function()
		task.wait(0.3)
		-- Strahl ausblenden
		local tweenOut = TweenService:Create(
			fx.beam,
			TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Width0 = 0, Width1 = 0 }
		)
		TweenService:Create(fx.light, TweenInfo.new(0.35), { Brightness = 0 }):Play()
		tweenOut:Play()
		tweenOut.Completed:Wait()
		fx.topAnchor:Destroy()
		fx.bottomAnchor:Destroy()
	end)
end

local function startEnchantBeam(swordPos: Vector3)
	-- Alten Effekt direkt abräumen falls noch aktiv
	if activeEnchantFx then
		activeEnchantFx.topAnchor:Destroy()
		activeEnchantFx.bottomAnchor:Destroy()
		activeEnchantFx = nil
	end

	-- Ursprung: Innenseite des Maschinenkopfs, nicht das Dach
	local topPos = Vector3.new(ENCHANT_X, ENCHANT_MACHINE_Y, ENCHANT_Z)
	local bottomPos = Vector3.new(swordPos.X, swordPos.Y + 0.5, swordPos.Z)

	local topAnchor = Instance.new("Part")
	topAnchor.Size = Vector3.new(0.05, 0.05, 0.05)
	topAnchor.Position = topPos
	topAnchor.Anchored = true
	topAnchor.CanCollide = false
	topAnchor.Transparency = 1
	topAnchor.Parent = Workspace

	local bottomAnchor = Instance.new("Part")
	bottomAnchor.Size = Vector3.new(0.05, 0.05, 0.05)
	bottomAnchor.Position = bottomPos
	bottomAnchor.Anchored = true
	bottomAnchor.CanCollide = false
	bottomAnchor.Transparency = 1
	bottomAnchor.Parent = Workspace

	local att0 = Instance.new("Attachment")
	att0.Parent = topAnchor
	local att1 = Instance.new("Attachment")
	att1.Parent = bottomAnchor

	local beam = Instance.new("Beam")
	beam.Attachment0 = att0
	beam.Attachment1 = att1
	beam.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, BEAM_COLOR),
		ColorSequenceKeypoint.new(0.5, BEAM_WHITE),
		ColorSequenceKeypoint.new(1, BEAM_COLOR),
	})
	beam.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(1, 0.15),
	})
	beam.Width0 = 0
	beam.Width1 = 0
	beam.LightEmission = 1
	beam.LightInfluence = 0
	beam.FaceCamera = true
	beam.Segments = 16
	beam.CurveSize0 = 0
	beam.CurveSize1 = 0
	beam.Parent = topAnchor

	-- Dauerlicht am Schwert
	local light = Instance.new("PointLight")
	light.Color = LIGHT_COLOR
	light.Brightness = 0
	light.Range = 14
	light.Parent = bottomAnchor

	-- Leiser Partikel-Dauerstrom (Burst kommt beim enchantEnd)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(Color3.fromRGB(210, 130, 255))
	emitter.LightEmission = 0.7
	emitter.LightInfluence = 0.2
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.25),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime = NumberRange.new(0.4, 0.8)
	emitter.Speed = NumberRange.new(2, 5)
	emitter.SpreadAngle = Vector2.new(40, 40)
	emitter.Rate = 18
	emitter.RotSpeed = NumberRange.new(-90, 90)
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.Parent = bottomAnchor

	activeEnchantFx = {
		topAnchor = topAnchor,
		bottomAnchor = bottomAnchor,
		beam = beam,
		light = light,
		emitter = emitter,
	}

	-- Strahl sanft einblenden
	TweenService
		:Create(
			beam,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Width0 = 0.7, Width1 = 0.7 }
		)
		:Play()
	TweenService:Create(light, TweenInfo.new(0.2), { Brightness = 7 }):Play()
end

-- ===== Event-Handler =====
factoryEvent.OnClientEvent:Connect(function(eventName, data)
	if eventName == "money" then
		goldLabel.Text = "💰 " .. tostring(data.money) .. " Gold"
		rankLabel.Text = "⚔️ " .. tostring(data.rankName)
		progressFill.Size = UDim2.fromScale(data.progress or 0, 1)
	elseif eventName == "bank" then
		bankLabel.Text = "🏦 " .. tostring(data.count) .. "/" .. tostring(data.capacity)
	elseif eventName == "toast" then
		showToast(data.text)
	elseif eventName == "openEnchanterGui" then
		openEnchanterGui()
	elseif eventName == "enchantStart" then
		startEnchantBeam(data.position)
	elseif eventName == "enchantEnd" then
		stopEnchantBeam(data.success)
	end
end)

-- ===== Schwert-Verbindung =====
local function triggerSlashAnimation(tool)
	local toolAnim = tool:FindFirstChild("toolanim")
	if not toolAnim then
		toolAnim = Instance.new("StringValue")
		toolAnim.Name = "toolanim"
		toolAnim.Parent = tool
	end
	toolAnim.Value = "Slash"
end

local function connectSword(tool)
	if tool:FindFirstChild(CONNECTED_MARKER) then
		return
	end

	local marker = Instance.new("BoolValue")
	marker.Name = CONNECTED_MARKER
	marker.Parent = tool

	tool.Activated:Connect(function()
		swordHitEvent:FireServer()
		triggerSlashAnimation(tool)
	end)

	swordPickedUpEvent:FireServer(tool)
end

local function connectChildTools(container)
	for _, child in container:GetChildren() do
		if child:IsA("Tool") and child.Name == SWORD_NAME then
			connectSword(child)
		end
	end

	container.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and child.Name == SWORD_NAME then
			connectSword(child)
		end
	end)
end

connectChildTools(player.Backpack)

player.CharacterAdded:Connect(function(character)
	connectChildTools(character)
end)

if player.Character then
	connectChildTools(player.Character)
end
