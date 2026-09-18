-- PlayerDataStore.luau - Persistente Spielerdaten (DataStoreService)
-- Speichert & laedt alle Spielerdaten. Ist absichtlich EIN zentraler Ort,
-- an dem neue Stats/Felder ergaenzt werden koennen, ohne dass alte Spielstaende
-- kaputt gehen: DEFAULT_DATA (via buildDefaultData) ist die "Schema"-Vorlage.
-- Fehlende Felder in gespeicherten Daten werden beim Laden automatisch aus
-- den Defaults aufgefuellt (deep merge). Vorhandene Werte bleiben unberuehrt.
--
-- ===== Neue Stats hinzufuegen =====
-- Einfach eine neue Zeile in buildDefaultData() (oder einer verschachtelten
-- Tabelle wie `upgrades`) ergaenzen. Bestehende Spieler bekommen den
-- Default-Wert beim naechsten Login automatisch dazu - ohne Migrationsskript,
-- ohne Datenverlust.
--
-- Beispiel: neuer Stat "critChance" -> in buildDefaultData() ergaenzen:
--   critChance = 0,
-- Fertig. Alte Speicherstaende bekommen critChance = 0 beim naechsten Laden.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SwordFactoryConfig"))

local PlayerDataStore = {}

local DATASTORE_NAME = "SwordFactory_PlayerData_v1"
local AUTOSAVE_INTERVAL = 120 -- Sekunden zwischen automatischen Zwischenspeicherungen
local SAVE_RETRY_COUNT = 3
local SAVE_RETRY_DELAY = 1 -- Sekunden, verdoppelt sich pro Versuch
local SHUTDOWN_MAX_WAIT = 25 -- Sekunden, die BindToClose max. auf Saves wartet

-- ===== Schema / Default-Werte =====
-- WICHTIG: Diese Funktion ist die einzige Quelle der Wahrheit fuer die
-- Datenstruktur. Neue Felder hier eintragen, nicht woanders im Code.
-- Als Funktion (nicht als Konstante), weil enchanterLevels von
-- Config.MAX_RARITY abhaengt - wird also automatisch groesser, falls
-- spaeter eine weitere Seltenheitsstufe ins Spiel kommt.
local function buildDefaultData()
	local enchanterLevels = {}
	for i = 1, Config.MAX_RARITY do
		enchanterLevels[i] = 0
	end

	return {
		money = 50,
		earnings = 0,
		rankIndex = 1,
		upgrades = {
			dropSpeed = 0,
			sellBoost = 0,
			baseValue = 0,
		},
		banked = {}, -- Array von { value, damage, rarity }
		enchanterLevels = enchanterLevels, -- { [rarityIndex] = level }

		-- Hier neue Top-Level-Stats ergaenzen, z.B.:
		-- critChance = 0,
		-- totalSwordsSold = 0,
	}
end

local dataStore = nil
do
	local ok, err = pcall(function()
		dataStore = DataStoreService:GetDataStore(DATASTORE_NAME)
	end)
	if not ok then
		warn("[PlayerDataStore] DataStore konnte nicht initialisiert werden: " .. tostring(err))
	end
end

-- ===== Deep-Merge =====
-- Fuellt fehlende Felder aus `defaults` in `target` auf. Vorhandene Werte in
-- `target` werden NIE ueberschrieben - nur ergaenzt. Untertabellen (upgrades,
-- enchanterLevels) werden rekursiv gemerged, damit auch dort neue Keys
-- automatisch nachgetragen werden. `banked` bleibt unberuehrt, weil sein
-- Default ({}) keine Keys zum Nachtragen hat.
local function deepMergeDefaults(target, defaults)
	for key, defaultValue in pairs(defaults) do
		if target[key] == nil then
			if type(defaultValue) == "table" then
				-- Tiefe Kopie, damit Spieler nicht dieselbe Tabellen-Referenz teilen.
				target[key] = deepMergeDefaults({}, defaultValue)
			else
				target[key] = defaultValue
			end
		elseif type(defaultValue) == "table" and type(target[key]) == "table" then
			deepMergeDefaults(target[key], defaultValue)
		end
	end
	return target
end

-- Liefert eine frische, unabhaengige Kopie der Default-Daten.
local function cloneDefaults()
	return deepMergeDefaults({}, buildDefaultData())
end

-- ===== Laden =====
-- Laedt die Daten eines Spielers. Gibt bei DataStore-Fehlern Default-Daten
-- zurueck, damit ein Ausfall den Spieler nicht komplett blockiert (er spielt
-- diese Session halt mit frischen Werten, statt gekickt zu werden).
function PlayerDataStore.load(userId)
	if not dataStore then
		return cloneDefaults()
	end

	local key = "Player_" .. tostring(userId)
	local success, result = pcall(function()
		return dataStore:GetAsync(key)
	end)

	if not success then
		warn("[PlayerDataStore] Laden fehlgeschlagen fuer " .. key .. ": " .. tostring(result))
		return cloneDefaults()
	end

	if result == nil then
		-- Neuer Spieler: frische Default-Daten.
		return cloneDefaults()
	end

	-- Bestehender Spieler: gespeicherte Daten + fehlende neue Felder auffuellen.
	return deepMergeDefaults(result, buildDefaultData())
end

-- ===== Speichern =====
-- Speichert mit Retry (DataStore-Requests koennen kurzfristig fehlschlagen,
-- z.B. bei Rate-Limits oder kurzen Netzwerk-Hickups).
function PlayerDataStore.save(userId, data)
	if not dataStore or not data then
		return false
	end

	local key = "Player_" .. tostring(userId)
	local delay = SAVE_RETRY_DELAY

	for attempt = 1, SAVE_RETRY_COUNT do
		local success, err = pcall(function()
			dataStore:SetAsync(key, data)
		end)
		if success then
			return true
		end
		warn(
			"[PlayerDataStore] Speichern fehlgeschlagen (Versuch "
				.. attempt
				.. "/"
				.. SAVE_RETRY_COUNT
				.. ") fuer "
				.. key
				.. ": "
				.. tostring(err)
		)
		if attempt < SAVE_RETRY_COUNT then
			task.wait(delay)
			delay *= 2
		end
	end

	return false
end

-- ===== Autosave-Loop =====
-- getStateFn(player) -> State-Tabelle oder nil. Wird periodisch fuer alle
-- Online-Spieler aufgerufen und gespeichert. Schuetzt vor Datenverlust bei
-- Server-Abstuerzen zwischen zwei PlayerRemoving-Saves.
function PlayerDataStore.startAutosave(getStateFn)
	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL)
			for _, player in ipairs(Players:GetPlayers()) do
				local state = getStateFn(player)
				if state then
					PlayerDataStore.save(player.UserId, state)
				end
			end
		end
	end)
end

-- ===== Server-Shutdown =====
-- In game:BindToClose() aufrufen: speichert alle Online-Spieler ab, bevor
-- der Server komplett schliesst. Wartet maximal SHUTDOWN_MAX_WAIT Sekunden.
function PlayerDataStore.saveAllOnShutdown(getStateFn)
	local players = Players:GetPlayers()
	if #players == 0 then
		return
	end

	local remaining = #players
	for _, player in ipairs(players) do
		task.spawn(function()
			local state = getStateFn(player)
			if state then
				PlayerDataStore.save(player.UserId, state)
			end
			remaining -= 1
		end)
	end

	local waited = 0
	while remaining > 0 and waited < SHUTDOWN_MAX_WAIT do
		task.wait(0.5)
		waited += 0.5
	end
end

return PlayerDataStore
