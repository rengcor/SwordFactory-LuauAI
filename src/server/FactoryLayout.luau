-- Sword Factory: baut das sichtbare Fabrik-Layout (nur Server).
-- Konstanten kommen aus dem geteilten Modul SwordFactoryConfig (ReplicatedStorage/Shared).
-- Layout-Idee: Fabrikband entlang der X-Achse (Z=6), Maschinen nördlich daneben (Z=18),
-- Service-Reihe (Schmiede/Bank/Kasse/Shops) bei Z=45. Alles weit verteilt, jede
-- Funktion bekommt ein erkennbares Gebaeude (kein Wuerfel-Allerlei).

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SwordFactoryConfig"))

local FactoryLayout = {}

-- ===== Farbpalette =====
local COLORS = {
	stone = Color3.fromRGB(140, 140, 150),
	stoneDark = Color3.fromRGB(90, 90, 100),
	roofRed = Color3.fromRGB(150, 60, 50),
	roofSlate = Color3.fromRGB(70, 70, 85),
	steel = Color3.fromRGB(150, 150, 160),
	steelDark = Color3.fromRGB(100, 100, 110),
	blue = Color3.fromRGB(130, 170, 230),
	blueDark = Color3.fromRGB(70, 110, 180),
	purple = Color3.fromRGB(140, 70, 200),
	purpleDark = Color3.fromRGB(90, 40, 140),
	green = Color3.fromRGB(60, 110, 70),
	greenDark = Color3.fromRGB(40, 80, 50),
	wood = Color3.fromRGB(140, 120, 95),
	woodDark = Color3.fromRGB(95, 80, 60),
	gold = Color3.fromRGB(255, 205, 60),
	rust = Color3.fromRGB(150, 70, 45),
	fire = Color3.fromRGB(255, 140, 40),
	belt = Color3.fromRGB(60, 60, 75),
	beltDark = Color3.fromRGB(35, 35, 45),
	glass = Color3.fromRGB(170, 210, 255),
	white = Color3.new(1, 1, 1),
}

-- ===== Basisfunktionen =====
local function makePart(name, size, position, color, transparency)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.Color = color
	if transparency then
		part.Transparency = transparency
	end
	part.Parent = Workspace
	return part
end

-- Schild ueber einem Anker schweben lassen. Das BillboardGui wird am Anker-Teil
-- selbst aufgehaengt (nicht in ReplicatedStorage), damit es in 3D gerendert wird.
local function addBillboard(anchorPart, text, offsetY, color)
	if not anchorPart then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Adornee = anchorPart
	gui.Size = UDim2.fromScale(22, 4)
	gui.AlwaysOnTop = true
	gui.StudsOffsetWorldSpace = Vector3.new(0, offsetY or 8, 0)
	gui.Parent = anchorPart

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Text = text
	label.TextColor3 = color or COLORS.white
	label.Parent = gui
end

-- Fundament unter ein Gebaeude legen (1 Stud dick, etwas groesser als der Bau)
local function addFoundation(name, cx, cz, width, depth, color)
	return makePart(name, Vector3.new(width, 1, depth), Vector3.new(cx, 0.5, cz), color or COLORS.stoneDark)
end

-- Gestuftes Flachdach (2 Lagen, schrumpfend) - sicher erkennbar, keine Rotation noetig
local function addSteppedRoof(name, cx, cz, width, depth, yBase, height, color, trimColor)
	local layer1 =
		makePart(name .. "Roof1", Vector3.new(width, height, depth), Vector3.new(cx, yBase + height / 2, cz), color)
	local innerW = math.max(2, width - 4)
	local innerD = math.max(2, depth - 4)
	makePart(name .. "Roof2", Vector3.new(innerW, height, innerD), Vector3.new(cx, yBase + height * 1.5, cz), color)
	if trimColor then
		makePart(name .. "Trim", Vector3.new(width, 0.3, depth), Vector3.new(cx, yBase - 0.15, cz), trimColor)
	end
	return layer1
end

-- ===== 1) Foerderband: durchgehende Bahn von x=0 bis x=160 auf Z=6 =====
-- Oberflaeche liegt auf Config.BELT_Y, damit die Schwerter darauf stehen koennen.
local function buildBelt()
	local straightLength = 128 -- schmale Bahn von x=0 bis x=128
	local segmentLength = 16
	local yCenter = Config.BELT_Y - 0.3 -- Band-Mitte: Oberflaeche = BELT_Y

	for i = 0, (straightLength / segmentLength) - 1 do
		local cx = i * segmentLength + segmentLength / 2
		makePart("Belt" .. i + 1, Vector3.new(segmentLength, 0.6, 3.4), Vector3.new(cx, yCenter, 6), COLORS.belt)
		-- Querstreifen (Roll-Optik)
		makePart(
			"BeltStripe" .. i + 1,
			Vector3.new(segmentLength, 0.7, 0.5),
			Vector3.new(cx, yCenter, 5.4),
			COLORS.beltDark
		)
		makePart(
			"BeltStripeB" .. i + 1,
			Vector3.new(segmentLength, 0.7, 0.5),
			Vector3.new(cx, yCenter, 6.6),
			COLORS.beltDark
		)
	end

	-- Rahmenstruktur: Quertraeger alle 16 Studs unter dem Band (industrieller Unterbau)
	for i = 0, straightLength / segmentLength do
		local bx = i * segmentLength
		makePart("BeltFrame" .. i + 1, Vector3.new(0.4, 0.8, 5), Vector3.new(bx, 0.4, 6), COLORS.steelDark)
	end

	-- Bodenplatte unter dem gesamten Band, damit es nicht auf dem Gras schwebt
	makePart(
		"BeltFloor",
		Vector3.new(straightLength, 0.4, 6),
		Vector3.new(straightLength / 2, 0.2, 6),
		COLORS.stoneDark
	)

	-- Trichter: das Band wird zum Ende hin breiter und laeuft buendig in die
	-- grosse Verkaufsbuehne (x=152..168, Breite 12) ueber. Schwerter, die an den
	-- Rand der Zone abgelegt werden, bleiben dadurch die ganze Zeit auf Flaeche.
	-- Gleiche Optik wie das restliche Band: dunkle Rand-Streifen (Roll-Optik)
	-- UND hellgraue Seiten-Bande (Rails) entlang der Trichterkanten.
	local funnel = {
		{ cx = 132, width = 5 }, -- 128..136
		{ cx = 140, width = 7 }, -- 136..144
		{ cx = 148, width = 9 }, -- 144..152
	}
	for index, segment in ipairs(funnel) do
		makePart(
			"BeltFunnel" .. index,
			Vector3.new(8, 0.6, segment.width),
			Vector3.new(segment.cx, yCenter, 6),
			COLORS.belt
		)

		-- Querstreifen wie beim normalen Band (dunkle Baender nahe der Raender)
		local stripeOffset = (segment.width / 2) - 0.45
		makePart(
			"BeltFunnelStripeL" .. index,
			Vector3.new(8, 0.7, 0.5),
			Vector3.new(segment.cx, yCenter, 6 - stripeOffset),
			COLORS.beltDark
		)
		makePart(
			"BeltFunnelStripeR" .. index,
			Vector3.new(8, 0.7, 0.5),
			Vector3.new(segment.cx, yCenter, 6 + stripeOffset),
			COLORS.beltDark
		)

		-- Hellgraue Seiten-Bande wie beim geraden Band (folgt der Trichterbreite)
		local railOffset = (segment.width / 2) + 0.2
		makePart(
			"BeltFunnelRailL" .. index,
			Vector3.new(8, 0.8, 0.4),
			Vector3.new(segment.cx, yCenter + 0.35, 6 - railOffset),
			COLORS.steelDark
		)
		makePart(
			"BeltFunnelRailR" .. index,
			Vector3.new(8, 0.8, 0.4),
			Vector3.new(segment.cx, yCenter + 0.35, 6 + railOffset),
			COLORS.steelDark
		)
	end

	-- Seitenbegrenzungen (nur bis zum Trichter, damit die Seiten offen sind).
	-- Schienen sind gegenueber dem alten Stand breiter/dicker.
	makePart(
		"BeltRailL",
		Vector3.new(straightLength, 1.0, 0.6),
		Vector3.new(straightLength / 2, yCenter + 0.35, 4.3),
		COLORS.steelDark
	)
	makePart(
		"BeltRailR",
		Vector3.new(straightLength, 1.0, 0.6),
		Vector3.new(straightLength / 2, yCenter + 0.35, 7.7),
		COLORS.steelDark
	)

	-- Verbindungsbolzen auf jeder Schiene (alle 32 Studs)
	for i = 0, 4 do
		local bx = i * 32
		makePart("BeltBoltL" .. i + 1, Vector3.new(1, 0.3, 0.3), Vector3.new(bx, yCenter + 1.0, 4.3), COLORS.steel)
		makePart("BeltBoltR" .. i + 1, Vector3.new(1, 0.3, 0.3), Vector3.new(bx, yCenter + 1.0, 7.7), COLORS.steel)
	end

	-- Rollen unter der Bahn (verdichtet: 8 Rollen, alle ~16 Studs)
	for i = 0, 7 do
		local rx = 8 + i * 16
		makePart("Roller" .. i + 1, Vector3.new(1.2, 0.6, 3), Vector3.new(rx, 0.3, 6), COLORS.beltDark)
	end

	-- Rollen unter dem Trichter
	makePart("RollerF1", Vector3.new(1.2, 0.6, 5), Vector3.new(134, 0.3, 6), COLORS.beltDark)
	makePart("RollerF2", Vector3.new(1.2, 0.6, 7), Vector3.new(143, 0.3, 6), COLORS.beltDark)
	makePart("RollerF3", Vector3.new(1.2, 0.6, 9), Vector3.new(150, 0.3, 6), COLORS.beltDark)

	-- Einlauftrichter-Gestell am Bandanfang (x=0): 2 Stahlpfosten + Querbalken
	makePart("BeltInletPostL", Vector3.new(0.5, 3, 0.5), Vector3.new(0, 1.5, 4.3), COLORS.steelDark)
	makePart("BeltInletPostR", Vector3.new(0.5, 3, 0.5), Vector3.new(0, 1.5, 7.7), COLORS.steelDark)
	makePart("BeltInletBeam", Vector3.new(0.5, 0.5, 3.4), Vector3.new(0, 3, 6), COLORS.steelDark)

	-- Uebergangsbogen am Bandende (x=152): 2 schmale Pfosten
	makePart("BeltExitPostL", Vector3.new(0.4, 2.5, 0.4), Vector3.new(152, 1.25, 4), COLORS.steelDark)
	makePart("BeltExitPostR", Vector3.new(0.4, 2.5, 0.4), Vector3.new(152, 1.25, 8), COLORS.steelDark)
end

-- ===== 2) Dropper: Trichter-Maschine direkt ueber dem Bandanfang =====
-- Auslauf haengt auf SWORD-CENTER-Hoehe, damit die Klinge direkt darunter spawnt.
local function buildDropper()
	local cx, cz = Config.DROPPER_POS.X, Config.DROPPER_POS.Z

	-- Erhoehte Plattform (1.5 hoch, 10x8) plus Treppe an der Suedseite
	makePart("DropperBase", Vector3.new(10, 1.5, 8), Vector3.new(cx, 0.75, cz), COLORS.stoneDark)
	makePart("DropperStep1", Vector3.new(4, 0.5, 1), Vector3.new(cx, 1.25, cz - 4.5), COLORS.stoneDark)
	makePart("DropperStep2", Vector3.new(4, 0.5, 1), Vector3.new(cx, 0.75, cz - 5.5), COLORS.stoneDark)
	makePart("DropperStep3", Vector3.new(4, 0.5, 1), Vector3.new(cx, 0.25, cz - 6.5), COLORS.stoneDark)

	makePart("DropperTankL", Vector3.new(1.5, 5, 4), Vector3.new(cx - 4, 5.5, cz), COLORS.steelDark)
	makePart("DropperTankR", Vector3.new(1.5, 5, 4), Vector3.new(cx + 4, 5.5, cz), COLORS.steelDark)

	-- Sichtstreifen (blaues Glas) auf der Frontseite jedes Tanks
	makePart("DropperTankLWindow", Vector3.new(0.8, 3, 0.2), Vector3.new(cx - 4, 5.5, cz - 2.1), COLORS.blue, 0.3)
	makePart("DropperTankRWindow", Vector3.new(0.8, 3, 0.2), Vector3.new(cx + 4, 5.5, cz - 2.1), COLORS.blue, 0.3)

	makePart("Dropper", Vector3.new(6, 2, 5), Vector3.new(cx, 8.2, cz), COLORS.rust) -- Trichter-Behälter

	-- Warnstreifen auf dem Trichter-Behaelter
	makePart("DropperStripe", Vector3.new(6.04, 0.4, 5.04), Vector3.new(cx, 7.6, cz), COLORS.beltDark)

	-- Bolzen an den 4 Ecken des Trichter-Behaelters
	local boltCorners = {
		Vector3.new(cx - 3, 8.2, cz - 2.5),
		Vector3.new(cx + 3, 8.2, cz - 2.5),
		Vector3.new(cx - 3, 8.2, cz + 2.5),
		Vector3.new(cx + 3, 8.2, cz + 2.5),
	}
	for i, pos in ipairs(boltCorners) do
		makePart("DropperBolt" .. i, Vector3.new(0.4, 0.4, 0.4), pos, COLORS.steel)
	end

	makePart("DropperNeck", Vector3.new(2, 2, 2.5), Vector3.new(cx, 6.6, cz), COLORS.steelDark) -- Auslauf
	makePart("DropperSpout", Vector3.new(1, 1.5, 1.5), Vector3.new(cx, 5, cz), COLORS.steel) -- Mundstueck

	-- Duennes Rohr zwischen Hals und Band (betont den Uebergang)
	makePart("DropperPipe", Vector3.new(0.6, 1.5, 0.6), Vector3.new(cx, 3.4, cz), COLORS.steelDark)

	local anchor = Workspace:FindFirstChild("Dropper")
	addBillboard(anchor, "Dropper", 10, COLORS.white)
end

-- ===== 3) Upgrade-Stationen: Tore UEBER dem Band (Z=6) =====
-- Die Schwerter fahren auf dem Band (Z=6) MITTIG durch die Tore - wie in einer
-- echten Fabrik wird an jeder Station etwas am Schwert veraendert. Die Pfeiler
-- stehen ausserhalb der Band-Rails (Z=4.3/7.7), der Querbalken ist so hoch,
-- dass die 3.9-Studs-Schwertspitze frei durchpasst.
local function buildStationTor(x, name, color, darkColor, accentColor, label, detailBuilder)
	-- Fundamente seitlich neben dem Band
	makePart(name .. "BaseL", Vector3.new(3, 1, 2), Vector3.new(x - 4.5, 0.5, 3.2), darkColor)
	makePart(name .. "BaseR", Vector3.new(3, 1, 2), Vector3.new(x + 4.5, 0.5, 8.8), darkColor)

	-- Pfeiler links/rechts vom Band
	makePart(name .. "PillarL", Vector3.new(2.5, 4.5, 2), Vector3.new(x - 4.5, 3.25, 3.2), color)
	makePart(name .. "PillarR", Vector3.new(2.5, 4.5, 2), Vector3.new(x + 4.5, 3.25, 8.8), color)

	-- Basis-Verbreiterung + Kapitell an jedem Pfeiler
	makePart(name .. "PillarLBase", Vector3.new(3, 1, 2.5), Vector3.new(x - 4.5, 1.5, 3.2), darkColor)
	makePart(name .. "PillarRBase", Vector3.new(3, 1, 2.5), Vector3.new(x + 4.5, 1.5, 8.8), darkColor)
	makePart(name .. "PillarLCap", Vector3.new(2.5, 0.4, 2), Vector3.new(x - 4.5, 5.7, 3.2), accentColor)
	makePart(name .. "PillarRCap", Vector3.new(2.5, 0.4, 2), Vector3.new(x + 4.5, 5.7, 8.8), accentColor)

	-- Querbalken (Tor) ueber dem Band -- Unterkante bei y=5.4, Schwert passt durch
	makePart(name .. "Beam", Vector3.new(12, 1.2, 7), Vector3.new(x, 6, 6), darkColor)

	-- Leuchtstreifen auf dem Querbalken links/rechts der Bandmitte
	makePart(name .. "BeamGlowL", Vector3.new(6, 0.2, 0.2), Vector3.new(x, 5.4, 4.4), accentColor, 0.3)
	makePart(name .. "BeamGlowR", Vector3.new(6, 0.2, 0.2), Vector3.new(x, 5.4, 7.6), accentColor, 0.3)

	-- Vertikale Rohre an der bandseitigen Innenseite jedes Pfeilers
	makePart(name .. "PipeL", Vector3.new(0.4, 4, 0.4), Vector3.new(x - 4.5, 3.25, 4.2), darkColor)
	makePart(name .. "PipeR", Vector3.new(0.4, 4, 0.4), Vector3.new(x + 4.5, 3.25, 7.8), darkColor)

	-- Maschinenkopf + Zierleiste auf dem Balken
	makePart(name .. "Head", Vector3.new(6, 1.5, 4), Vector3.new(x, 7.3, 6), color)
	makePart(name .. "Trim", Vector3.new(6.6, 0.5, 4.6), Vector3.new(x, 8.2, 6), accentColor)

	if detailBuilder then
		detailBuilder(x, name)
	end

	local anchor = Workspace:FindFirstChild(name .. "Beam")
	addBillboard(anchor, label, 11, COLORS.white)
end

local function sharpenerDetail(x, name)
	-- Silberne Klinge auf dem Dach des Tores
	makePart(name .. "Blade", Vector3.new(8, 1.2, 3), Vector3.new(x, 9, 6), COLORS.white)
	-- Schleifscheiben links/rechts der Klinge (Zylinder-Imitation)
	makePart(name .. "WheelL", Vector3.new(1, 0.4, 1), Vector3.new(x - 4, 9, 6), COLORS.steelDark)
	makePart(name .. "WheelR", Vector3.new(1, 0.4, 1), Vector3.new(x + 4, 9, 6), COLORS.steelDark)
end

local function polisherDetail(x, name)
	-- Polier-Teller liegt FLACH auf dem Torkopf - steht nie auf der Bandlinie
	makePart(name .. "Wheel", Vector3.new(3.2, 0.5, 3.2), Vector3.new(x, 8.1, 6), Color3.fromRGB(200, 220, 240))
	makePart(name .. "WheelHub", Vector3.new(1, 0.6, 1), Vector3.new(x, 8.6, 6), COLORS.steelDark)
	-- Antriebsgehaeuse unter dem Polier-Teller
	makePart(name .. "Drive", Vector3.new(1.5, 1, 1.5), Vector3.new(x, 7.0, 4.3), COLORS.blueDark)
end

local function enchanterDetail(x, name)
	-- Leuchtender Kristall auf dem Dach des Tores
	makePart(name .. "Crystal", Vector3.new(3, 2, 3), Vector3.new(x, 9, 6), COLORS.purpleDark)
	makePart(name .. "Gem", Vector3.new(1.4, 1.4, 1.4), Vector3.new(x, 10.8, 6), Color3.fromRGB(255, 120, 255), 0.2)
	-- 4 Energiepunkte im Quadrat unter dem Kristall
	local energyPositions = {
		Vector3.new(x - 0.8, 7.5, 6 - 0.8),
		Vector3.new(x + 0.8, 7.5, 6 - 0.8),
		Vector3.new(x - 0.8, 7.5, 6 + 0.8),
		Vector3.new(x + 0.8, 7.5, 6 + 0.8),
	}
	for i, pos in ipairs(energyPositions) do
		makePart(name .. "Energy" .. i, Vector3.new(0.4, 0.4, 0.4), pos, Color3.fromRGB(200, 100, 255), 0.2)
	end
end

-- ===== 4) Verkaufszone: grosse Buehne am Bandende (x=160) mit Goldtor =====
-- Die Buehnen-Oberflaeche liegt EXAKT auf BELT_Y (=Bandhoehe), damit ankommende
-- Schwerter ohne Absatz zu ihren Ablageplaetzen gleiten (kein Schweben).
local function buildSellZone()
	local cx, cz = Config.SELL_ZONE_POS.X, Config.SELL_ZONE_POS.Z

	-- Empfangsboden unter der Buehne
	makePart("SellFloor", Vector3.new(18, 0.4, 14), Vector3.new(cx, 0.2, cz), COLORS.stone)

	-- Buehne: 16x1.2x12, Oberkante bei y=1.2 = BELT_Y
	local stage = makePart("SellStage", Vector3.new(16, 1.2, 12), Vector3.new(cx, 0.6, cz), COLORS.stone)
	-- Einstiegs-Stufe an der Suedseite (hoeheres Niveau trotzdem begehbar)
	makePart("SellStep", Vector3.new(16, 0.6, 2), Vector3.new(cx, 0.3, cz - 6.9), COLORS.stoneDark)

	-- Goldkanten oben auf der Buehne
	makePart("SellGoldL", Vector3.new(16, 0.3, 0.4), Vector3.new(cx, 1.35, cz - 5.9), COLORS.gold)
	makePart("SellGoldR", Vector3.new(16, 0.3, 0.4), Vector3.new(cx, 1.35, cz + 5.9), COLORS.gold)

	-- Ablagemarkierungen auf der Buehne (zeigen, wo die Schwerter landen)
	for i = -1, 1 do
		makePart("SellSpot" .. (i + 2), Vector3.new(1.5, 0.1, 1.5), Vector3.new(cx + i * 4, 1.25, cz), COLORS.gold, 0.5)
	end

	-- Rueckwand am noerdlichen Buehnenrand (Abschluss der Zone)
	makePart("SellBackWall", Vector3.new(16, 4, 0.5), Vector3.new(cx, 3.2, cz + 5.75), COLORS.stoneDark)

	-- Verkaufstor (Bogen) - Pfeiler sind dicker als vorher
	makePart("SellPillarL", Vector3.new(1.4, 5, 1.4), Vector3.new(cx - 5, 3, cz), COLORS.steelDark)
	makePart("SellPillarR", Vector3.new(1.4, 5, 1.4), Vector3.new(cx + 5, 3, cz), COLORS.steelDark)
	makePart("SellBeam", Vector3.new(12, 1, 1.2), Vector3.new(cx, 6, cz), COLORS.gold)
	-- Bogen zwischen den Pfeilern oben
	makePart("SellArch", Vector3.new(3, 0.8, 0.8), Vector3.new(cx, 6.9, cz), COLORS.gold)
	-- Licht-Akzente auf den Pfeilerkoepfen
	makePart("SellPillarLGlow", Vector3.new(1, 0.5, 1), Vector3.new(cx - 5, 5.75, cz), COLORS.gold, 0.4)
	makePart("SellPillarRGlow", Vector3.new(1, 0.5, 1), Vector3.new(cx + 5, 5.75, cz), COLORS.gold, 0.4)

	addBillboard(stage, "Verkaufszone (15 s Auto-Verkauf)", 12, Color3.fromRGB(1, 0.9, 0.6))
end

-- ===== 5) Raritaets-Schmiede: Steinhaus mit Schornstein und Feuer =====
local function buildForge()
	local cx, cz = Config.RARITY_FORGE_POS.X, Config.RARITY_FORGE_POS.Z

	addFoundation("ForgeBase", cx, cz, 8, 8)
	makePart("ForgeHouse", Vector3.new(8, 3.5, 8), Vector3.new(cx, 2.25, cz), COLORS.stoneDark)
	addSteppedRoof("Forge", cx, cz, 8, 8, 4, 1, COLORS.roofRed, COLORS.roofSlate)
	makePart("ForgeChimney", Vector3.new(1.5, 4, 1.5), Vector3.new(cx + 3, 6, cz - 3), COLORS.stoneDark)

	-- Schornstein-Oeffnung oben als Kappe + Rauch-Andeutung
	makePart("ForgeChimneyCap", Vector3.new(2, 0.5, 2), Vector3.new(cx + 3, 8.25, cz - 3), COLORS.beltDark)
	makePart("ForgeSmoke1", Vector3.new(1.2, 1.2, 1.2), Vector3.new(cx + 3, 9.2, cz - 3), COLORS.stone, 0.5)
	makePart("ForgeSmoke2", Vector3.new(1.2, 1.2, 1.2), Vector3.new(cx + 3, 10.4, cz - 3), COLORS.stone, 0.6)
	makePart("ForgeSmoke3", Vector3.new(1.2, 1.2, 1.2), Vector3.new(cx + 3, 11.6, cz - 3), COLORS.stone, 0.7)

	-- Eingangstuer + Tuerrahmen an der Suedseite
	makePart("ForgeDoor", Vector3.new(2.5, 3, 0.4), Vector3.new(cx, 2.5, cz - 4.1), COLORS.woodDark)
	makePart("ForgeDoorFrame", Vector3.new(3, 3.4, 0.5), Vector3.new(cx, 2.5, cz - 3.9), COLORS.stoneDark)

	-- Fenster links/rechts der Tuer
	makePart("ForgeWindowL", Vector3.new(1.5, 1.5, 0.3), Vector3.new(cx - 3, 2.5, cz - 4.1), COLORS.glass, 0.4)
	makePart("ForgeWindowR", Vector3.new(1.5, 1.5, 0.3), Vector3.new(cx + 3, 2.5, cz - 4.1), COLORS.glass, 0.4)

	-- Feuermund
	makePart("ForgeFire", Vector3.new(2.5, 2.5, 0.5), Vector3.new(cx, 2.2, cz + 4), COLORS.fire)
	makePart("ForgeFireGlow", Vector3.new(2.5, 2.5, 0.4), Vector3.new(cx, 2.2, cz + 3.7), COLORS.fire, 0.4)

	-- Kohlen/Glut vor dem Feuermund
	makePart("ForgeCoal1", Vector3.new(0.5, 0.3, 0.5), Vector3.new(cx - 0.8, 0.7, cz + 3.2), COLORS.fire)
	makePart("ForgeCoal2", Vector3.new(0.5, 0.3, 0.5), Vector3.new(cx, 0.7, cz + 3.0), Color3.fromRGB(255, 80, 30))
	makePart("ForgeCoal3", Vector3.new(0.5, 0.3, 0.5), Vector3.new(cx + 0.8, 0.7, cz + 3.2), COLORS.fire)

	-- Stilisierter Amboss vor dem Eingang
	makePart("ForgeAnvilBase", Vector3.new(2, 0.5, 1.5), Vector3.new(cx, 0.75, cz - 5.5), COLORS.steelDark)
	makePart("ForgeAnvilHead", Vector3.new(1.8, 0.6, 1), Vector3.new(cx, 1.3, cz - 5.5), COLORS.steel)

	local anchor = Workspace:FindFirstChild("ForgeHouse")
	addBillboard(anchor, "Raritaets-Schmiede", 8.5, Color3.fromRGB(1, 0.8, 0.6))
end

-- ===== 6) Bank: gruener Tresor mit Goldtuer und Saeulen =====
local function buildBank()
	local cx, cz = Config.BANK_POS.X, Config.BANK_POS.Z

	-- Erhoehte Sockelplatte unter dem Vault-Quader
	makePart("BankSockel", Vector3.new(12, 0.6, 11), Vector3.new(cx, 0.3, cz), COLORS.stoneDark)

	addFoundation("BankBase", cx, cz, 10, 9)
	makePart("BankVault", Vector3.new(10, 5, 9), Vector3.new(cx, 3, cz), COLORS.green)
	addSteppedRoof("Bank", cx, cz, 10, 9, 5.7, 0.8, COLORS.greenDark, COLORS.gold)

	-- Goldtuer mit Rahmen
	makePart("BankDoor", Vector3.new(3, 4, 0.5), Vector3.new(cx, 2.5, cz - 4.4), COLORS.gold)
	makePart("BankDoorFrame", Vector3.new(3.6, 4.6, 0.5), Vector3.new(cx, 2.5, cz - 4.1), COLORS.stoneDark)

	-- Gesims ueber der Tuer (Verdachung)
	makePart("BankCornice", Vector3.new(4, 0.5, 0.5), Vector3.new(cx, 4.7, cz - 4.4), COLORS.gold)

	-- Fenster links/rechts der Tuer
	makePart("BankWindowL", Vector3.new(1.5, 1.5, 0.3), Vector3.new(cx - 2.75, 2.5, cz - 4.4), COLORS.glass, 0.4)
	makePart("BankWindowR", Vector3.new(1.5, 1.5, 0.3), Vector3.new(cx + 2.75, 2.5, cz - 4.4), COLORS.glass, 0.4)

	-- Saeulen vorn
	makePart("BankColumnL", Vector3.new(0.8, 4.5, 0.8), Vector3.new(cx - 4.4, 2.5, cz - 4.2), COLORS.gold)
	makePart("BankColumnR", Vector3.new(0.8, 4.5, 0.8), Vector3.new(cx + 4.4, 2.5, cz - 4.2), COLORS.gold)

	-- Kapitell + Basis an jeder Saeule
	makePart("BankColumnLCap", Vector3.new(1, 0.5, 1), Vector3.new(cx - 4.4, 5.0, cz - 4.2), COLORS.gold)
	makePart("BankColumnRCap", Vector3.new(1, 0.5, 1), Vector3.new(cx + 4.4, 5.0, cz - 4.2), COLORS.gold)
	makePart("BankColumnLBase", Vector3.new(1, 0.4, 1), Vector3.new(cx - 4.4, 0.45, cz - 4.2), COLORS.stoneDark)
	makePart("BankColumnRBase", Vector3.new(1, 0.4, 1), Vector3.new(cx + 4.4, 0.45, cz - 4.2), COLORS.stoneDark)

	-- Eingangsstufen vor der Suedseite
	makePart("BankStep1", Vector3.new(10, 0.4, 1), Vector3.new(cx, 0.6, cz - 5.25), COLORS.stoneDark)
	makePart("BankStep2", Vector3.new(11, 0.4, 1), Vector3.new(cx, 0.2, cz - 6.25), COLORS.stoneDark)

	local anchor = Workspace:FindFirstChild("BankVault")
	addBillboard(anchor, "Bank (Einlagern)", 9.5, Color3.fromRGB(0.9, 1, 0.85))
end

-- ===== 7) Verkaufs-Kasse: goldener Kiosk mit Markise =====
local function buildBankSell()
	local cx, cz = Config.BANK_SELL_POS.X, Config.BANK_SELL_POS.Z

	addFoundation("KassaBase", cx, cz, 6, 5)
	makePart("KassaCounter", Vector3.new(6, 2, 5), Vector3.new(cx, 1.5, cz), COLORS.wood)
	makePart("KassaTop", Vector3.new(6, 0.4, 5), Vector3.new(cx, 2.8, cz), COLORS.gold)

	-- Kassenautomat auf dem Tresen (leicht versetzt)
	makePart("KassaRegister", Vector3.new(0.8, 1, 0.5), Vector3.new(cx + 0.5, 3.5, cz + 1), COLORS.steelDark)

	-- Schubladenandeutung unter dem Tresen
	makePart("KassaDrawer", Vector3.new(3.5, 0.4, 0.3), Vector3.new(cx, 2.0, cz - 2.4), COLORS.woodDark)

	-- Markise auf zwei Stuetzen
	makePart("KassaPostL", Vector3.new(0.5, 2, 0.5), Vector3.new(cx - 2.8, 3.4, cz), COLORS.woodDark)
	makePart("KassaPostR", Vector3.new(0.5, 2, 0.5), Vector3.new(cx + 2.8, 3.4, cz), COLORS.woodDark)
	makePart("KassaAwning", Vector3.new(7, 0.4, 5.5), Vector3.new(cx, 4.5, cz), COLORS.roofRed)

	-- Fransen der Markise (ein Stud tiefer als die Markise)
	for i = 1, 4 do
		local fx = cx - 1.5 + (i - 1)
		makePart("KassaFringe" .. i, Vector3.new(0.3, 0.4, 5.5), Vector3.new(fx, 3.5, cz), COLORS.roofRed)
	end

	-- Runde Bodenmatte unter der Kasse
	makePart("KassaMat", Vector3.new(4, 0.2, 4), Vector3.new(cx, 0.1, cz - 2.5), COLORS.wood, 0.3)

	local anchor = Workspace:FindFirstChild("KassaCounter")
	addBillboard(anchor, "Kasse (Bank verkaufen)", 7, Color3.fromRGB(1, 0.95, 0.8))
end

-- ===== 8) Shops: ein gemeinsamer Marktplatz mit drei Schaettern =====
-- Die drei Upgrade-Laeden stehen unter einer einzigen Markthalle: durchgehendes
-- Fundament, Rueckwand mit Bogen-Fenstern, gestuftes Dach mit Goldrand, Saeulen
-- an den Trennpunkten und drei einzeln erkennbare Tresen.
local function buildShops()
	local marketCx, marketCz = 170, 45

	local shopData = {
		{ color = Color3.fromRGB(255, 90, 80), text = "Shop: Dropper-Tempo" },
		{ color = Color3.fromRGB(90, 150, 255), text = "Shop: Verkaufs-Boost" },
		{ color = Color3.fromRGB(250, 200, 60), text = "Shop: Basiswert" },
	}

	-- 1) Durchgehendes Fundament (56x10) plus begehbare Einstiegs-Stufe
	addFoundation("MarketBase", marketCx, marketCz, 56, 10, COLORS.stoneDark)
	makePart("MarketStep", Vector3.new(56, 0.5, 1.5), Vector3.new(marketCx, 0.25, 39.4), COLORS.stoneDark)

	-- 2) Rueckwand (Breite 56, Hoehe 7) an der Nordseite
	makePart("MarketBackWall", Vector3.new(56, 7, 0.5), Vector3.new(marketCx, 4.5, 49.2), COLORS.stone)

	-- 3) Gestuftes Dach ueber dem gesamten Gebaeude mit Goldrand
	local roof = addSteppedRoof("Market", marketCx, marketCz, 56, 10, 7.5, 1, COLORS.roofSlate, COLORS.gold)
	-- Goldene Dachleisten auf den Dachkanten
	makePart("MarketRoofEdgeF", Vector3.new(56, 0.3, 0.4), Vector3.new(marketCx, 8.65, 40.2), COLORS.gold)
	makePart("MarketRoofEdgeB", Vector3.new(56, 0.3, 0.4), Vector3.new(marketCx, 8.65, 49.8), COLORS.gold)
	makePart("MarketRoofEdgeL", Vector3.new(0.4, 0.3, 10), Vector3.new(142.2, 8.65, marketCz), COLORS.gold)
	makePart("MarketRoofEdgeR", Vector3.new(0.4, 0.3, 10), Vector3.new(197.8, 8.65, marketCz), COLORS.gold)

	-- 4) Saeulen an den Trennpunkten (X=160 und X=180) mit Goldkapitellen
	for _, columnX in ipairs({ 160, 180 }) do
		makePart("MarketColumn" .. columnX, Vector3.new(1.2, 6.5, 1.2), Vector3.new(columnX, 4.25, 40.2), COLORS.stone)
		makePart(
			"MarketColumn" .. columnX .. "Cap",
			Vector3.new(1.4, 0.4, 1.4),
			Vector3.new(columnX, 7.6, 40.2),
			COLORS.gold
		)
	end

	-- 5) Drei individuelle Schaetler: Tresen, farbiger Hintergrund, Beschilderung
	for index, shop in ipairs(shopData) do
		local pos = Config.SHOP_POSITIONS[index]
		local cx, cz = pos.X, pos.Z

		-- Tresen (Anker fuer das Schalter-Schild)
		makePart("Shop" .. index .. "Stall", Vector3.new(4, 1.5, 2), Vector3.new(cx, 1.75, cz), COLORS.wood)
		makePart("Shop" .. index .. "CounterTop", Vector3.new(4.4, 0.3, 2.4), Vector3.new(cx, 2.6, cz), COLORS.woodDark)

		-- Farbiges Regal/Hintergrund-Panel hinter dem Tresen
		makePart("Shop" .. index .. "Shelf", Vector3.new(4, 4, 0.6), Vector3.new(cx, 3.5, cz + 1.6), shop.color)
		makePart(
			"Shop" .. index .. "ShelfTop",
			Vector3.new(4.2, 0.3, 0.8),
			Vector3.new(cx, 5.6, cz + 1.6),
			COLORS.woodDark
		)

		-- Bogen-Fenster in Shop-Farbe in der Rueckwand
		makePart("Shop" .. index .. "Arch", Vector3.new(4, 4, 0.5), Vector3.new(cx, 4, cz + 3.8), shop.color, 0.25)
		makePart("Shop" .. index .. "ArchTop", Vector3.new(4.4, 1, 0.5), Vector3.new(cx, 6.4, cz + 3.8), COLORS.stone)
		makePart(
			"Shop" .. index .. "ArchSill",
			Vector3.new(4.4, 0.3, 0.5),
			Vector3.new(cx, 1.85, cz + 3.8),
			COLORS.stoneDark
		)

		-- Kleine Beschilderung vorn am Tresen
		makePart("Shop" .. index .. "Sign", Vector3.new(2.2, 0.6, 0.2), Vector3.new(cx, 2.3, cz - 1.5), COLORS.woodDark)

		-- Leuchtender Akzent (Beleuchtungs-Andeutung) auf dem Regal
		makePart("Shop" .. index .. "Glow", Vector3.new(1, 1, 0.3), Vector3.new(cx, 3.2, cz + 1.4), shop.color, 0.4)

		-- Faehnchen auf der Dachkante in Shop-Farbe
		makePart(
			"Shop" .. index .. "FlagPole",
			Vector3.new(0.15, 1.2, 0.15),
			Vector3.new(cx, 8.9, 40.2),
			COLORS.steelDark
		)
		makePart("Shop" .. index .. "Flag", Vector3.new(0.8, 0.4, 0.15), Vector3.new(cx + 0.45, 9.35, 40.2), shop.color)

		local anchor = Workspace:FindFirstChild("Shop" .. index .. "Stall")
		addBillboard(anchor, shop.text, 4.5, COLORS.white)
	end

	-- 6) Grosses Schild ueber dem gesamten Markt
	addBillboard(roof, "🏪 Upgrade-Markt", 6, COLORS.gold)
end

-- ===== 9) Hilfe-Schild am Eingang =====
local function buildHelpSign()
	-- Zwei Pfosten + Querbalken oben
	makePart("HelpPostL", Vector3.new(0.5, 4.5, 0.5), Vector3.new(-11, 2.25, 14), COLORS.woodDark)
	makePart("HelpPostR", Vector3.new(0.5, 4.5, 0.5), Vector3.new(-5, 2.25, 14), COLORS.woodDark)
	makePart("HelpCrossbar", Vector3.new(6, 0.4, 0.4), Vector3.new(-8, 4.6, 14), COLORS.woodDark)

	-- Steinbasis unter den Pfosten
	makePart("HelpBase", Vector3.new(3, 0.4, 1), Vector3.new(-8, 0.2, 14), COLORS.stoneDark)

	-- Vergroessertes Schildbrett mit Goldrand dahinter
	makePart("HelpBoardBack", Vector3.new(8.4, 2.4, 0.3), Vector3.new(-8, 5.3, 14.1), COLORS.gold)
	local board = makePart("HelpBoard", Vector3.new(8, 2, 0.5), Vector3.new(-8, 5.3, 14), COLORS.roofSlate)

	-- Holzpfeil-Deko rechts vom Schild (Richtungsandeutung)
	makePart("HelpArrow1", Vector3.new(1, 0.3, 0.3), Vector3.new(-2, 5.3, 14), COLORS.woodDark)
	makePart("HelpArrow2", Vector3.new(1, 0.3, 0.3), Vector3.new(-0.8, 5.3, 14), COLORS.woodDark)

	addBillboard(board, "Schwerter droppen -> Maschinen -> Verkaufszone (15 s)", 7, Color3.fromRGB(1, 1, 0.8))
end


-- Baut einmalig alle sichtbaren Bereiche der Fabrik
function FactoryLayout.build()
	buildBelt()
	buildDropper()
	buildStationTor(
		40,
		"Sharpener",
		COLORS.steel,
		COLORS.steelDark,
		COLORS.white,
		"Schleifer: +Schaden",
		sharpenerDetail
	)
	buildStationTor(
		80,
		"Polisher",
		COLORS.blue,
		COLORS.blueDark,
		Color3.fromRGB(200, 220, 240),
		"Polierer: +Wert",
		polisherDetail
	)
	buildStationTor(
		120,
		"Enchanter",
		COLORS.purple,
		COLORS.purpleDark,
		Color3.fromRGB(255, 120, 255),
		"Verzauberer: +Raritaet",
		enchanterDetail
	)
	buildSellZone()
	buildForge()
	buildBank()
	buildBankSell()
	buildShops()
	buildHelpSign()
	-- Knopf-Pfosten neben dem Verzauberer (x=120, z=3 = nördlich, nicht auf dem Band)
	-- Der Server (init.server.luau) haengt den ClickDetector per "EnchanterBtn" dran.
	local btnPost = Instance.new("Part")
	btnPost.Name = "EnchanterBtnPost"
	btnPost.Size = Vector3.new(0.5, 4, 0.5)
	btnPost.Position = Vector3.new(126, 2, 3)
	btnPost.Anchored = true
	btnPost.CanCollide = false
	btnPost.Color = Color3.fromRGB(80, 80, 90)
	btnPost.Material = Enum.Material.SmoothPlastic
	btnPost.Parent = Workspace

	local btn = Instance.new("Part")
	btn.Name = "EnchanterBtn"
	btn.Size = Vector3.new(1.2, 1.2, 0.5)
	btn.Position = Vector3.new(126, 4.2, 3)
	btn.Anchored = true
	btn.CanCollide = false
	btn.Color = Color3.fromRGB(80, 200, 100)
	btn.Material = Enum.Material.Neon
	btn.Parent = Workspace

	local btnCornerMesh = Instance.new("SpecialMesh")
	btnCornerMesh.MeshType = Enum.MeshType.Brick
	btnCornerMesh.Parent = btn

	addBillboard(btn, "✨ Upgrades", 3, Color3.fromRGB(180, 255, 180))
end

return FactoryLayout
