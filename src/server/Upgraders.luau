-- Sword Factory: die drei Upgrader-Stationen (nur Server).
-- Jede Station hat eine onArrive-Funktion, die das Foerderband aufruft, sobald
-- ein Schwert anhaelt (nach der Standzeit). Nur die Stats werden veraendert,
-- die Bewegung uebernimmt der ConveyorBelt.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SwordFactoryConfig"))

local Upgraders = {}

-- Station 1: Schleifer -> +1 Schaden
function Upgraders.applySharpening(tool)
	local damage = tool:FindFirstChild("SwordDamage")
	if damage then
		damage.Value += 1
	end
end

-- Station 2: Polierer -> +3 Wert
function Upgraders.applyPolishing(tool)
	local value = tool:FindFirstChild("SwordValue")
	if value then
		value.Value += 3
	end
end

-- Station 3: Verzauberer -> Raritaet +1 (max MAX_RARITY), Klingenfarbe wechselt.
-- Jede Stufe hat eine Erfolgschance (Config.ENCHANT_CHANCES): je seltener die
-- Ziel-Raritaet, desto geringer. Schlaegt der Versuch fehl, bleibt das
-- Schwert auf seiner aktuellen Raritaet.
-- enchanterBonus (0.0..1.0): addiert sich auf die Basiswahrscheinlichkeit,
-- gesetzt von init.server.luau ueber setEnchanterBonus().
-- enchanterBonuses[i] = additive Bonus (0..1) fuer Raritaets-Aufstieg i.
-- Index i = Aufstieg von Raritaet i zu i+1 (1=Gewoehnlich->Ungewoehnlich, usw.)
local enchanterBonuses = {}

-- Setzt alle Boni auf einmal (Tabelle { [1..MAX_RARITY] = bonus }).
function Upgraders.setEnchanterBonuses(bonuses)
	enchanterBonuses = bonuses or {}
end

-- Compat-Shim: altes setEnchanterBonus(scalar) befuellt alle Slots gleichmaessig.
function Upgraders.setEnchanterBonus(bonus)
	for i = 1, Config.MAX_RARITY do
		enchanterBonuses[i] = bonus or 0
	end
end

function Upgraders.applyEnchanting(tool)
	local rarity = tool:FindFirstChild("SwordRarity")
	if not rarity or rarity.Value >= Config.MAX_RARITY then
		return
	end

	-- Neue Logik: Wenn mehrere Stufen auf 100% sind, gewinnt die hoechste.
	-- 1) Von hoechster moeglicher Ziel-Raritaet abwaerts: erste mit chance=1.0 -> sofort.
	-- 2) Falls keine auf 100%: hoeichste Stufe mit chance>0 und Zufallswurf.
	local targetRarity = nil

	-- Pass 1: gibt es eine Stufe mit 100% Chance? Dann die hoechste nehmen.
	for ri = Config.MAX_RARITY, rarity.Value + 1, -1 do
		local baseChance = Config.ENCHANT_CHANCES[ri] or 0
		local bonus = enchanterBonuses[ri] or 0
		local chance = math.min(1, baseChance + bonus)
		if chance >= 1 then
			targetRarity = ri -- hoechste Stufe mit garantiertem Erfolg
			break
		end
	end

	-- Pass 2: keine garantierte Stufe -> hoeichste Stufe mit chance>0, Zufallswurf.
	if not targetRarity then
		for ri = Config.MAX_RARITY, rarity.Value + 1, -1 do
			local baseChance = Config.ENCHANT_CHANCES[ri] or 0
			local bonus = enchanterBonuses[ri] or 0
			local chance = math.min(1, baseChance + bonus)
			if chance > 0 and math.random() <= chance then
				targetRarity = ri
				break
			end
		end
	end

	if not targetRarity then
		return -- alle Wuerfe fehlgeschlagen
	end

	rarity.Value = targetRarity

	local blade = tool:FindFirstChild("Blade")
	if blade then
		blade.Color = Config.RARITY_COLORS[rarity.Value + 1]
	end
end

return Upgraders
