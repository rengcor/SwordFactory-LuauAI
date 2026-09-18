-- init.server.luau - Main Server Entry Point

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ===== Module =====
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SwordFactoryConfig"))
local Sword = require(script:WaitForChild("Sword"))
local Enemy = require(script:WaitForChild("Enemy"))
local FactoryLayout = require(script:WaitForChild("FactoryLayout"))
local SwordDropper = require(script:WaitForChild("SwordDropper"))
local ConveyorBelt = require(script:WaitForChild("ConveyorBelt"))
local Upgraders = require(script:WaitForChild("Upgraders"))
local PlayerDataStore = require(script:WaitForChild("PlayerDataStore"))

-- ===== RemoteEvents zuerst erstellen =====
local function ensureRemoteEvent(name: string): RemoteEvent
	local existing = ReplicatedStorage:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end
	local re = Instance.new("RemoteEvent")
	re.Name = name
	re.Parent = ReplicatedStorage
	return re
end

local function ensureRemoteFunction(name: string): RemoteFunction
	local existing = ReplicatedStorage:FindFirstChild(name)
	if existing and existing:IsA("RemoteFunction") then
		return existing
	end
	local rf = Instance.new("RemoteFunction")
	rf.Name = name
	rf.Parent = ReplicatedStorage
	return rf
end

local swordHitEvent = ensureRemoteEvent("SwordHitEvent")
local swordPickedUpEvent = ensureRemoteEvent("SwordPickedUpEvent")
local factoryEvent = ensureRemoteEvent(Config.FACTORY_EVENT_NAME)
local enchanterGuiFunc = ensureRemoteFunction("EnchanterGuiFunc")

print("Sword Factory Server starting...")

-- ===== Spieler-Daten (persistent via DataStore) =====
local playerStates = {}

local function getState(player)
	if not playerStates[player] then
		playerStates[player] = PlayerDataStore.load(player.UserId)
	end
	return playerStates[player]
end

-- ===== Event-Helfer =====
local function sendEvent(player, eventName, data)
	factoryEvent:FireClient(player, eventName, data)
end

local function sendToast(player, text)
	sendEvent(player, "toast", { text = text })
end

-- ===== leaderstats =====
local function setupLeaderstats(player, state)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local rang = Instance.new("StringValue")
	rang.Name = "Rang"
	rang.Value = Config.RANKS[state.rankIndex].name
	rang.Parent = leaderstats
	leaderstats.Parent = player
end

local function updateLeaderstatsRank(player, rankName)
	local leaderstats = player:FindFirstChild("leaderstats")
	local rang = leaderstats and leaderstats:FindFirstChild("Rang")
	if rang then
		rang.Value = rankName
	end
end

-- ===== Rang & Money =====
local function getRankIndex(earnings)
	local idx = 1
	for i, rank in ipairs(Config.RANKS) do
		if earnings >= rank.earnings then
			idx = i
		end
	end
	return idx
end

local function broadcastMoney(player, state)
	local rankName = Config.RANKS[state.rankIndex].name
	local nextRank = Config.RANKS[state.rankIndex + 1]
	local progress = 0
	if nextRank then
		local prevEarnings = Config.RANKS[state.rankIndex].earnings
		progress = math.clamp((state.earnings - prevEarnings) / math.max(1, nextRank.earnings - prevEarnings), 0, 1)
	else
		progress = 1
	end
	sendEvent(player, "money", {
		money = state.money,
		rankName = rankName,
		progress = progress,
	})
end

local function updateRank(player, state)
	local newIdx = getRankIndex(state.earnings)
	if newIdx ~= state.rankIndex then
		state.rankIndex = newIdx
		local rankName = Config.RANKS[newIdx].name
		updateLeaderstatsRank(player, rankName)
		sendToast(player, "🎉 Rang erreicht: " .. rankName .. "!")
	end
end

local function sendBankUpdate(player, state)
	local BANK_CAP = 5
	sendEvent(player, "bank", {
		count = #(state.banked or {}),
		capacity = BANK_CAP,
	})
end

-- ===== Sell-Handler =====
local function maxUpgradeLevel(key)
	local maxLvl = 0
	for _, ps in pairs(playerStates) do
		local upgrades = ps.upgrades or {}
		maxLvl = math.max(maxLvl, upgrades[key] or 0)
	end
	return maxLvl
end

local function swordEarnedValue(tool, state)
	local value = tool:FindFirstChild("SwordValue")
	local rarity = tool:FindFirstChild("SwordRarity")
	local sv = value and value.Value or 10
	local rv = rarity and rarity.Value or 0
	local boost = (state.upgrades and state.upgrades.sellBoost) or 0
	return math.floor(sv * (1 + 0.5 * rv) * (1 + 0.1 * boost) * (1 + 0.05 * (state.rankIndex - 1)))
end

local function sellSword(tool)
	local sellPos = Config.SELL_ZONE_POS
	local bestPlayer = nil
	local bestDist = 30

	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root then
			local dist = (root.Position - sellPos).Magnitude
			if dist < bestDist then
				bestDist = dist
				bestPlayer = player
			end
		end
	end

	if not bestPlayer then
		local all = Players:GetPlayers()
		if #all > 0 then
			bestPlayer = all[1]
		end
	end

	if bestPlayer then
		local state = getState(bestPlayer)
		local earned = swordEarnedValue(tool, state)
		state.money += earned
		state.earnings += earned
		updateRank(bestPlayer, state)
		broadcastMoney(bestPlayer, state)
	end

	tool:Destroy()
end

ConveyorBelt.setSellHandler(sellSword)

-- ===== Dropper -> Band =====
local function getDropperInterval()
	return math.max(2, 8 - 1.5 * maxUpgradeLevel("dropSpeed"))
end

local BASE_VALUE_PER_LEVEL = 5
local function getBaseValue()
	return 10 + BASE_VALUE_PER_LEVEL * maxUpgradeLevel("baseValue")
end

SwordDropper.setIntervalGetter(getDropperInterval)
SwordDropper.setBaseValueGetter(getBaseValue)

SwordDropper.setOnSwordCreated(function(tool)
	task.spawn(function()
		ConveyorBelt.runSword(tool)
	end)
end)

SwordDropper.setSpawnBlocker(function()
	return ConveyorBelt.isBusy()
end)

-- ===== SwordPickedUp =====
swordPickedUpEvent.OnServerEvent:Connect(function(_player, tool)
	if typeof(tool) ~= "Instance" or not tool:IsA("Tool") then
		return
	end
	local handle = tool:FindFirstChild("BeltHandle") or tool:FindFirstChild("Handle")
	if handle then
		handle.Anchored = false
		handle.CanCollide = true
	end
	local blade = tool:FindFirstChild("Blade")
	if blade then
		blade.Anchored = false
		blade.CanCollide = false
	end
end)

-- ===== SwordHit =====
swordHitEvent.OnServerEvent:Connect(function(_player)
	-- Trefferlogik laeuft server-seitig in Sword.luau (tool.Activated).
end)

-- ===== Enchanter GUI =====
local ENCHANT_UPGRADE_STEP = 0.15

local function getEnchanterBonuses()
	-- Hoechste gekaufte Stufe ueber alle Spieler bestimmt die globale Chance.
	local bonuses = {}
	for i = 1, Config.MAX_RARITY do
		local maxLvl = 0
		for _, ps in pairs(playerStates) do
			if ps.enchanterLevels then
				maxLvl = math.max(maxLvl, ps.enchanterLevels[i] or 0)
			end
		end
		bonuses[i] = maxLvl * ENCHANT_UPGRADE_STEP
	end
	return bonuses
end

local ENCHANT_UPGRADE_COSTS = { 50, 120, 280, 600 }

local function buildEnchanterGuiData(state)
	local rows = {}
	local bonuses = getEnchanterBonuses()
	for i = 1, Config.MAX_RARITY do
		local base = Config.ENCHANT_CHANCES[i] or 0
		local bonus = bonuses[i] or 0
		local chance = math.min(1, base + bonus)
		local level = state.enchanterLevels and (state.enchanterLevels[i] or 0) or 0
		local maxed = level >= 5 or chance >= 1
		local col = Config.RARITY_COLORS[i + 1]
		rows[i] = {
			name = Config.RARITY_NAMES[i] .. " → " .. Config.RARITY_NAMES[i + 1],
			chancePercent = math.floor(chance * 100),
			level = level,
			maxed = maxed,
			nextCost = maxed and -1 or (ENCHANT_UPGRADE_COSTS[i] or 999),
			colorR = math.floor(col.R * 255),
			colorG = math.floor(col.G * 255),
			colorB = math.floor(col.B * 255),
		}
	end
	return { rows = rows }
end

enchanterGuiFunc.OnServerInvoke = function(player, request)
	if not request then
		return nil
	end
	local state = getState(player)

	if request.action == "getState" then
		return buildEnchanterGuiData(state)
	elseif request.action == "buy" then
		local idx = request.rarityIndex
		if not idx or idx < 1 or idx > Config.MAX_RARITY then
			return { ok = false, message = "Ungueltige Raritaet." }
		end
		local cost = ENCHANT_UPGRADE_COSTS[idx] or 999
		if not state.enchanterLevels then
			state.enchanterLevels = {}
			for i = 1, Config.MAX_RARITY do
				state.enchanterLevels[i] = 0
			end
		end
		local level = state.enchanterLevels[idx] or 0
		if level >= 5 then
			return { ok = false, message = "Bereits voll ausgebaut!" }
		end
		if state.money < cost then
			return { ok = false, message = "Zu wenig Gold! (" .. cost .. " benoetigt)" }
		end
		state.money -= cost
		state.enchanterLevels[idx] = level + 1
		-- Globale Boni neu berechnen und an Upgraders weitergeben
		Upgraders.setEnchanterBonuses(getEnchanterBonuses())
		broadcastMoney(player, state)
		return { ok = true, guiData = buildEnchanterGuiData(state) }
	end

	return nil
end

-- ===== EnchanterBtn ClickDetector =====
task.defer(function()
	local btn = Workspace:FindFirstChild("EnchanterBtn")
	if not btn then
		warn("EnchanterBtn nicht gefunden – FactoryLayout noch nicht gebaut?")
		return
	end
	local cd = Instance.new("ClickDetector")
	cd.MaxActivationDistance = 12
	cd.Parent = btn
	cd.MouseClick:Connect(function(player)
		sendEvent(player, "openEnchanterGui", {})
	end)
end)

-- ===== PlayerAdded / PlayerRemoving =====
Players.PlayerAdded:Connect(function(player)
	local state = getState(player)
	setupLeaderstats(player, state)
	-- Kurz warten bis Client geladen ist, dann HUD befuellen
	task.wait(2)
	broadcastMoney(player, state)
	sendBankUpdate(player, state)
	-- Globale Enchanter-Boni aktualisieren
	Upgraders.setEnchanterBonuses(getEnchanterBonuses())

	-- /money Debug-Command
	player.Chatted:Connect(function(msg)
		local lower = msg:lower()
		local sign, numStr = lower:match("^/money%s+([%+%-]?)(%d+)$")
		if not numStr then
			return
		end
		local amount = tonumber(numStr) or 0
		local ps = getState(player)
		if sign == "+" or sign == "" then
			ps.money = ps.money + amount
			ps.earnings = ps.earnings + amount
			updateRank(player, ps)
			broadcastMoney(player, ps)
			sendToast(player, "[Debug] +" .. amount .. " Gold")
		elseif sign == "-" then
			ps.money = math.max(0, ps.money - amount)
			broadcastMoney(player, ps)
			sendToast(player, "[Debug] -" .. amount .. " Gold")
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	local state = playerStates[player]
	if state then
		PlayerDataStore.save(player.UserId, state)
	end
	playerStates[player] = nil
end)

-- ===== Persistenz: Autosave & Shutdown =====
PlayerDataStore.startAutosave(function(player)
	return playerStates[player]
end)

game:BindToClose(function()
	PlayerDataStore.saveAllOnShutdown(function(player)
		return playerStates[player]
	end)
end)

-- ===== Systeme starten =====
Sword.setupStarterPack()
Enemy.setupSpawning()
FactoryLayout.build()
SwordDropper.start()

print("Sword Factory Server ready!")
