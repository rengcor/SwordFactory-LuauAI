-- Sword Factory: geteilte Konfiguration (Server UND Client).
-- Liegt in ReplicatedStorage/Shared, damit beide Seiten dasselbe require() können.
-- Laut offizieller Roblox-Doku: ModuleScript laeuft einmal, gibt genau einen Wert zurueck.

local Config = {}

-- ===== Fabrik-Layout =====
-- Band-Linie verlaeuft entlang der X-Achse bei Z = 6 (weite Verteilung auf der Map):
-- 0 Dropper  |  40 Schleifer  |  80 Polierer  |  120 Verzauberer  |  160 Verkaufszone
Config.BELT_Y = 1.2 -- Hoehe der Band-Oberflaeche
-- Schlanke Schwertform: Griff (0.5 hoch) auf Band, Klinge (2.2 hoch) darueber
Config.SWORD_HANDLE_Y = Config.BELT_Y + 0.25 -- Mitte des Handle-Parts = Transport-Anker
Config.DROPPER_POS = Vector3.new(0, Config.BELT_Y, 6)
Config.STATION_SHARPEN_POS = Vector3.new(40, Config.BELT_Y, 6)
Config.STATION_POLISH_POS = Vector3.new(80, Config.BELT_Y, 6)
Config.STATION_ENCHANT_POS = Vector3.new(120, Config.BELT_Y, 6)
Config.SELL_ZONE_POS = Vector3.new(160, Config.BELT_Y, 6)
Config.BELT_STOP_DURATION = 3.0 -- Sekunden pro Band-Abschnitt (schwimmt langsam)
Config.STATION_DWELL_TIME = 3.0 -- Sekunden, die ein Schwert an einer Upgrader-Station steht
Config.SELL_TIMEOUT = 15 -- Sekunden bis Auto-Verkauf in der Zone

-- Service-Reihe bei Z = 45 (nördlich des Bands), weit auseinandergezogen
Config.RARITY_FORGE_POS = Vector3.new(40, 2, 45) -- Raritaets-Schmiede
Config.BANK_POS = Vector3.new(90, 2, 45) -- Bank (einlagern)
Config.BANK_SELL_POS = Vector3.new(110, 2, 45) -- Verkaufs-Kasse
Config.SHOP_POSITIONS = {
	Vector3.new(150, 2, 45),
	Vector3.new(170, 2, 45),
	Vector3.new(190, 2, 45),
}

-- ===== Raritaeten =====
Config.MAX_RARITY = 4
Config.RARITY_NAMES = { "Gewöhnlich", "Ungewöhnlich", "Selten", "Episch", "Legendär" }
Config.RARITY_COLORS = {
	Color3.fromRGB(150, 150, 150), -- Gewöhnlich
	Color3.fromRGB(80, 200, 80), -- Ungewöhnlich
	Color3.fromRGB(70, 130, 230), -- Selten
	Color3.fromRGB(180, 70, 220), -- Episch
	Color3.fromRGB(240, 150, 30), -- Legendär
}

-- Erfolgschance des Verzauberers pro Raritaetsstufe (0..1).
-- Index 1 = Aufstieg von Gewoehnlich auf Ungewoehnlich, usw.
-- Startwerte: Ungewoehnlich 25%, alle anderen 0% (steigerbar via GUI-Upgrades).
Config.ENCHANT_CHANCES = {
	0.25, -- Gewöhnlich   -> Ungewöhnlich
	0.0, -- Ungewöhnlich  -> Selten
	0.0, -- Selten        -> Episch
	0.0, -- Episch        -> Legendär
}
Config.ENCHANT_FAIL_KEEPS_SWORD = true

-- ===== Raenge =====
Config.RANKS = {
	{ name = "Schwertling", earnings = 0 },
	{ name = "Klingenschleifer", earnings = 100 },
	{ name = "Schmied", earnings = 300 },
	{ name = "Schmiedemeister", earnings = 750 },
	{ name = "Klingenlegende", earnings = 1500 },
	{ name = "Schwertkönig", earnings = 3000 },
}

-- ===== Events =====
Config.SWORD_NAME = "Sword"
Config.FACTORY_EVENT_NAME = "FactoryEvent"

return Config
