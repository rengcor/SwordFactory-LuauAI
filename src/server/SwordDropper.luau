-- Sword Factory: der Schwert-Dropper (nur Server).
-- Laeuft als Hintergrund-Task und erzeugt Fabrik-Schwerter mit Stats (IntValues).
-- Es kommt IMMER nur dann ein neues Schwert, wenn der Platz direkt unter dem
-- Dropper-Auslauf frei ist - so bildet sich kein Haufen.
-- Die Schwerter stehen auf dem Band (Fuesse auf BELT_Y) und haben die gleiche
-- schlanke Form wie das Trainings-Schwert (Griff + Klinge), damit sie sich
-- aufgenommen nicht dick anfuehlen. Solange sie auf dem Band liegen, sind sie
-- verankert und CanCollide=false -> nicht aufhebbar (erst Verkaufszone, Schritt 6).

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SwordFactoryConfig"))

local Dropper = {}

local BASE_VALUE = 10 -- Startwert (wird an den Upgradern erhoeht)
local BASE_DAMAGE = 1 -- Startschaden
local DROPPER_BASE_INTERVAL = 12 -- Sekunden zwischen zwei Spawn-Versuchen
local DROPPER_MIN_INTERVAL = 4 -- schnellstes Tempo (ab Schritt 8 erreichbar)
local DROPPER_FREE_RADIUS = 3 -- Studs: gilt als "belegt", wenn ein Schwert so nah liegt

-- Wird ab Schritt 8 vom Shop erhoeht (Dropper-Tempo)
local dropSpeedLevel = 0

-- Schritt 8: Getter, die von init.server.luau gesetzt werden. Liefern das
-- aktuelle Spawn-Intervall bzw. den Startwert neuer Schwerter (beruecksichtigt
-- die hoechste Upgrade-Stufe aller Spieler).
local intervalGetter = nil
local baseValueGetter = nil

-- Wird von init.server.luau gesetzt: erhaelt jedes frisch gespawnte Schwert,
-- damit z. B. das Foerderband (Schritt 4) es direkt weiterbewegen kann.
local onSwordCreated = nil

-- Optionaler Spawn-Blocker: wird vor jedem neuen Spawn geprueft. Liefert er true,
-- wartet der Dropper (z. B. solange noch ein Schwert auf dem Band unterwegs ist,
-- damit sich nichts aufstaut - Schritt 5).
local spawnBlocker = nil

function Dropper.setSpawnBlocker(callback)
	spawnBlocker = callback
end

function Dropper.setOnSwordCreated(callback)
	onSwordCreated = callback
end

function Dropper.setDropSpeedLevel(level)
	dropSpeedLevel = level
end

function Dropper.setIntervalGetter(callback)
	intervalGetter = callback
end

function Dropper.setBaseValueGetter(callback)
	baseValueGetter = callback
end

function Dropper.dropperInterval()
	if intervalGetter then
		return intervalGetter()
	end
	return math.max(DROPPER_MIN_INTERVAL, DROPPER_BASE_INTERVAL - 1.6 * dropSpeedLevel)
end

-- Kleine zufaellige Abweichung, damit das Schwert nicht perfekt mittig klatscht
local function jitter()
	return (math.random() - 0.5) * 0.6
end

-- Baut ein schlankes Fabrik-Schwert (Griff + Klinge) und stellt es unter den Dropper.
local function createFactorySword()
	local x = Config.DROPPER_POS.X + jitter()
	local z = Config.DROPPER_POS.Z + jitter()

	local tool = Instance.new("Tool")
	tool.Name = Config.SWORD_NAME -- wie das Trainings-Schwert -> Client-Hook greift automatisch

	local handle = Instance.new("Part")
	handle.Name = "BeltHandle" -- bewusst NICHT "Handle": sonst koennte man es auf dem Band aufheben
	-- (Roblox-Tool-Auto-Pickup reagiert auf den Teil-Namen "Handle").
	-- Erst beim Ablegen in der Verkaufszone wird es in "Handle" umbenannt.
	handle.Size = Vector3.new(0.4, 0.5, 0.4)
	handle.Color = Color3.fromRGB(101, 67, 33) -- brauner Griff
	handle.Position = Vector3.new(x, Config.SWORD_HANDLE_Y, z)
	handle.Anchored = true -- bleibt auf dem Band stehen; wird beim Ablegen wieder geloest (Conveyor)
	handle.CanCollide = false
	handle.Parent = tool

	local blade = Instance.new("Part")
	blade.Name = "Blade"
	blade.Size = Vector3.new(0.22, 2.2, 0.22)
	blade.Color = Config.RARITY_COLORS[1] -- Gewoehnlich (Raritaetsfarbe)
	blade.Position = Vector3.new(x, Config.SWORD_HANDLE_Y + 1.35, z)
	blade.Anchored = true -- auf dem Band nicht herumrutschen, beim Aufheben loest der Server das
	blade.CanCollide = false
	blade.Parent = tool

	-- Griff und Klinge verschweissen, damit das Schwert zusammenhaelt
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = blade
	weld.Parent = handle

	local value = Instance.new("IntValue")
	value.Name = "SwordValue"
	value.Value = baseValueGetter and baseValueGetter() or BASE_VALUE
	value.Parent = tool

	local damage = Instance.new("IntValue")
	damage.Name = "SwordDamage"
	damage.Value = BASE_DAMAGE
	damage.Parent = tool

	local rarity = Instance.new("IntValue")
	rarity.Name = "SwordRarity"
	rarity.Value = 0 -- 0..MAX_RARITY (siehe Config)
	rarity.Parent = tool

	tool.Parent = Workspace
	return tool
end

-- Liegt aktuell ein Fabrik-Schwert in Dropper-Naehe (im Workspace)?
-- Aufgehobene Schwerter sind im Backpack/Character, nicht im Workspace -> zaehlen nicht.
function Dropper.isDropperFree()
	local dropperX, dropperZ = Config.DROPPER_POS.X, Config.DROPPER_POS.Z
	for _, child in Workspace:GetChildren() do
		if child:IsA("Tool") and child.Name == Config.SWORD_NAME then
			-- Auf dem Band heisst der Teil "BeltHandle" (gegen Auto-Pickup),
			-- in der Verkaufszone "Handle" - beides findet den Griff
			local handle = child:FindFirstChild("Handle") or child:FindFirstChild("BeltHandle")
			if handle then
				local dx = handle.Position.X - dropperX
				local dz = handle.Position.Z - dropperZ
				if math.sqrt(dx * dx + dz * dz) < DROPPER_FREE_RADIUS then
					return false
				end
			end
		end
	end
	return true
end

local function dropperLoop()
	while true do
		task.wait(Dropper.dropperInterval())
		if #Players:GetPlayers() > 0 then
			-- Warten, bis der Platz unter dem Dropper frei ist
			while not Dropper.isDropperFree() do
				task.wait(0.5)
			end
			-- Warten, bis das Band wieder frei ist (kein Stau auf der Strecke)
			while spawnBlocker and spawnBlocker() do
				task.wait(0.5)
			end

			local tool = createFactorySword()
			if onSwordCreated then
				onSwordCreated(tool)
			end
		end
	end
end

function Dropper.start()
	task.spawn(dropperLoop)
end

return Dropper
