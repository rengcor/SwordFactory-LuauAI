-- Sword Factory: das Foerderband (nur Server).
-- Bewegt fertige Fabrik-Schwerter vom Dropper durch die 3 Upgrader-Stationen
-- bis in die Verkaufszone. Auf dem Band ist das Teil als "BeltHandle" benannt,
-- damit es dort NICHT aufgehoben werden kann (Roblox-Tool-Pickup braucht ein
-- Teil mit dem Namen "Handle"). Beim Ankommen wird das Schwert auf einen FREIEN
-- Ablageplatz der Verkaufszone gefahren und erst dort freigegeben (umbenannt zu
-- "Handle" + entankert) - so verteilen sich die Schwerter ueber die Buehne und
-- man hebt nicht alle auf einem Haufen auf.

local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SwordFactoryConfig"))
-- Die drei Upgrader-Stationen (Schleifer/Polierer/Verzauberer)
local Upgraders = require(script.Parent:WaitForChild("Upgraders"))

local ConveyorBelt = {}

-- Optionaler Sell-Handler: wird von init.server.luau gesetzt (Schritt 7).
-- Wenn gesetzt, ruft der letzte Band-Stop diesen Handler statt releaseInSellZone auf.
local sellHandler = nil

function ConveyorBelt.setSellHandler(fn)
	sellHandler = fn
end

-- Anzahl Schwerter, die gerade auf dem Band unterwegs sind. Solange > 0 wartet
-- der Dropper mit einem neuen Schwert (kein Stau auf dem Band).
local busyCount = 0

function ConveyorBelt.isBusy()
	return busyCount > 0
end

-- Ab dieser Naehe (in Studs) nimmt ein Spieler ein abgelegtes Schwert auf
local PICKUP_RADIUS = 3
-- Abstand zwischen den Naehe-Checks in Sekunden
local PICKUP_INTERVAL = 0.25

-- Wegpunkte: X/Z aus Config, Y auf Handle-Hoehe (Schwert steht auf dem Band)
local function handleHeight(stopPosition)
	return Vector3.new(stopPosition.X, Config.SWORD_HANDLE_Y, stopPosition.Z)
end

-- ==========================================================================
-- Ablage in der Verkaufszone: Die Schwerter werden ueber die GANZE Buehne
-- verteilt (freie Streuung mit Mindestabstand) statt auf feste Plaetze - so
-- gibt es keinen Stapel in der Mitte und keine zu dicht liegenden Schwerter.
-- Die Buehne (16x12 Studs bei x=160, z=6) liegt auf Bandhoehe (BELT_Y).
-- ==========================================================================
local SCATTER_MIN_X = Config.SELL_ZONE_POS.X - 6
local SCATTER_MAX_X = Config.SELL_ZONE_POS.X + 6
local SCATTER_MIN_Z = Config.SELL_ZONE_POS.Z - 4.5
local SCATTER_MAX_Z = Config.SELL_ZONE_POS.Z + 4.5
local SCATTER_MIN_DISTANCE = 3.5 -- Mindestabstand zwischen zwei Schwertern
local SCATTER_ATTEMPTS = 24 -- Versuche, einen gut verteilten Platz zu finden

-- Alle noch liegenden Schwerter (im Workspace) einsammeln
local function settledSwordPositions()
	local positions = {}
	for _, child in Workspace:GetChildren() do
		if child:IsA("Tool") and child.Name == Config.SWORD_NAME then
			local part = child:FindFirstChild("Handle") or child:FindFirstChild("BeltHandle")
			if part then
				table.insert(positions, part.Position)
			end
		end
	end
	return positions
end

-- Horizontale Distanz zweier Punkte
local function horizontalDistance(a, b)
	local dx = a.X - b.X
	local dz = a.Z - b.Z
	return math.sqrt(dx * dx + dz * dz)
end

-- Naechsten freien, gut verteilten Ablageplatz finden
local function findScatterSpot()
	local settled = settledSwordPositions()
	local bestSpot = Vector3.new(Config.SELL_ZONE_POS.X, Config.SWORD_HANDLE_Y, Config.SELL_ZONE_POS.Z)
	local bestDistance = -math.huge

	for _ = 1, SCATTER_ATTEMPTS do
		local candidate = Vector3.new(
			SCATTER_MIN_X + math.random() * (SCATTER_MAX_X - SCATTER_MIN_X),
			Config.SWORD_HANDLE_Y,
			SCATTER_MIN_Z + math.random() * (SCATTER_MAX_Z - SCATTER_MIN_Z)
		)

		local nearest = math.huge
		for _, pos in ipairs(settled) do
			nearest = math.min(nearest, horizontalDistance(candidate, pos))
		end

		if nearest >= SCATTER_MIN_DISTANCE then
			return candidate -- genug Abstand zu allen anderen -> perfekt
		end

		if nearest > bestDistance then
			bestDistance = nearest
			bestSpot = candidate
		end
	end

	return bestSpot -- sonst: am weitesten entfernt von allen anderen
end

-- Schwert in der Verkaufszone aufhebbar machen.
-- WICHTIG: Der eingebaute Tool-Pickup ist auf dem Band deaktiviert (Teil heisst
-- "BeltHandle") und laesst sich per Runtime-Rename nicht zuverlaessig reaktivieren
-- (die Pickup-Bindung entsteht beim Erzeugen). Deshalb laeuft ein eigener
-- Naehe-Check: Der naechste Spieler bekommt das Schwert direkt in den Backpack.
local function enablePickupSword(tool, handle)
	task.spawn(function()
		while tool.Parent == Workspace do
			local nearestPlayer = nil
			local nearestDistance = PICKUP_RADIUS

			for _, player in Players:GetPlayers() do
				local root = nil
				local character = player.Character
				if character then
					root = character:FindFirstChild("HumanoidRootPart")
				end
				if root then
					local distance = (root.Position - handle.Position).Magnitude
					if distance < nearestDistance then
						nearestDistance = distance
						nearestPlayer = player
					end
				end
			end

			if nearestPlayer then
				-- Normal als Schwert ausruestbar machen und in den Backpack legen
				handle.Name = "Handle"
				handle.Anchored = false
				handle.CanCollide = true
				local blade = tool:FindFirstChild("Blade")
				if blade then
					blade.Anchored = false
					blade.CanCollide = true
				end
				tool.Parent = nearestPlayer.Backpack
				return
			end

			task.wait(PICKUP_INTERVAL)
		end
	end)
end

-- Ablage in der Verkaufszone: liegen lassen und Aufheben scharf schalten
local function releaseInSellZone(tool)
	local handle = tool:FindFirstChild("BeltHandle") or tool:FindFirstChild("Handle")
	if not handle then
		return
	end
	handle.Anchored = false
	handle.CanCollide = true
	local blade = tool:FindFirstChild("Blade")
	if blade then
		blade.Anchored = false
		blade.CanCollide = true
	end
	enablePickupSword(tool, handle)
end

-- Drei Upgrader-Stationen + Verkaufszone. An den Stationen haelt das Schwert
-- kurz an (dwellSeconds) und bekommt dann seine Verbesserung (Schritt 5).
local BELT_STOPS = {
	{
		positionFunction = function()
			return handleHeight(Config.STATION_SHARPEN_POS)
		end,
		onArrive = Upgraders.applySharpening,
		dwellSeconds = Config.STATION_DWELL_TIME,
	},
	{
		positionFunction = function()
			return handleHeight(Config.STATION_POLISH_POS)
		end,
		onArrive = Upgraders.applyPolishing,
		dwellSeconds = Config.STATION_DWELL_TIME,
	},
	{
		positionFunction = function()
			return handleHeight(Config.STATION_ENCHANT_POS)
		end,
		onEnter = function(tool, handle)
			-- Schwert ist angekommen: Strahl starten
			local factoryEvent = ReplicatedStorage:FindFirstChild("FactoryEvent")
			if factoryEvent then
				local pos = handle and handle.Position or Vector3.new(Config.STATION_ENCHANT_POS.X, 3, 6)
				factoryEvent:FireAllClients("enchantStart", { position = pos })
			end
		end,
		onArrive = function(tool, handle)
			local rarityBefore = tool:FindFirstChild("SwordRarity")
			local rarityValueBefore = rarityBefore and rarityBefore.Value or 0
			Upgraders.applyEnchanting(tool)
			local rarityAfter = tool:FindFirstChild("SwordRarity")
			local success = rarityAfter and rarityAfter.Value > rarityValueBefore
			-- Strahl stoppen + Ergebnis-Burst
			local factoryEvent = ReplicatedStorage:FindFirstChild("FactoryEvent")
			if factoryEvent then
				local pos = handle and handle.Position or Vector3.new(Config.STATION_ENCHANT_POS.X, 3, 6)
				factoryEvent:FireAllClients("enchantEnd", {
					position = pos,
					success = success,
				})
			end
		end,
		dwellSeconds = Config.STATION_DWELL_TIME,
	},
	{
		positionFunction = findScatterSpot,
		onArrive = function(tool, _handle)
			-- Schwert 15 Sekunden liegen lassen, dann Auto-Verkauf ausloesen.
			-- releaseInSellZone macht es aufhebbar; nach dem Delay wird es
			-- ueber den sellHandler verkauft (falls noch im Workspace).
			releaseInSellZone(tool)
			task.delay(Config.SELL_TIMEOUT, function()
				if tool and tool.Parent == Workspace and sellHandler then
					sellHandler(tool)
				end
			end)
		end,
	},
}

-- Faehrt ein Schwert einmal komplett ueber das Band bis in die Verkaufszone.
-- Jede Station: ankommen -> kurz stehen bleiben (dwell) -> Verbesserung -> weiter.
-- WICHTIG: Handle UND Klinge (Blade) werden zusammen bewegt - ein Tween nur auf
-- den Griff zieht die Klinge NACH (Weld folgt nicht), sie bleibt sonst zurueck.
local function runSwordInner(tool)
	local handle = tool:FindFirstChild("BeltHandle") or tool:FindFirstChild("Handle")
	if not handle then
		return
	end

	-- Offset der Klinge relativ zum Griff (bleibt waehrend der Fahrt konstant)
	local blade = tool:FindFirstChild("Blade")
	local bladeOffset = Vector3.new(0, 0, 0)
	if blade then
		bladeOffset = blade.Position - handle.Position
	end

	for _, stop in ipairs(BELT_STOPS) do
		-- Schwert wurde aufgehoben oder entfernt? Dann Fahrt abbrechen.
		if tool.Parent ~= Workspace then
			return
		end

		local destination = stop.positionFunction()

		local tween = TweenService:Create(
			handle,
			TweenInfo.new(Config.BELT_STOP_DURATION, Enum.EasingStyle.Linear),
			{ Position = destination }
		)
		tween:Play()

		-- Klinge synchron mitziehen
		if blade then
			local bladeTween = TweenService:Create(
				blade,
				TweenInfo.new(Config.BELT_STOP_DURATION, Enum.EasingStyle.Linear),
				{ Position = destination + bladeOffset }
			)
			bladeTween:Play()
		end

		tween.Completed:Wait()

		-- Schwert ist angekommen: onEnter feuern (z.B. Strahl starten)
		if stop.onEnter then
			stop.onEnter(tool, handle)
		end

		-- Kurz in der Station stehen bleiben, dann Upgrader anwenden
		if stop.dwellSeconds and stop.dwellSeconds > 0 then
			task.wait(stop.dwellSeconds)
		end

		if stop.onArrive then
			stop.onArrive(tool, handle)
		end
	end
end

function ConveyorBelt.runSword(tool)
	busyCount += 1
	runSwordInner(tool)
	busyCount -= 1
end

return ConveyorBelt
