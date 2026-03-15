-- ==========================================================================
-- ModernRP UI - 2026 Edition v2
-- Custom HUD + Full Scoreboard + Custom F4 Menu + Chat + /played
-- ==========================================================================

ModernRPUI = ModernRPUI or {}
local ui = ModernRPUI

-- ── THEME ────────────────────────────────────────────────────────────────

ui.Theme = {
	bg       = Color(8, 12, 18, 238),
	surface  = Color(14, 20, 28, 228),
	raised   = Color(22, 30, 40, 222),
	card     = Color(18, 25, 34, 232),
	border   = Color(255, 255, 255, 10),
	divider  = Color(255, 255, 255, 8),
	text     = Color(235, 240, 245),
	sub      = Color(140, 155, 168),
	muted    = Color(68, 80, 90),
	acBlue   = Color(88, 166, 255),
	acCyan   = Color(86, 228, 220),
	acGreen  = Color(108, 195, 126),
	acGold   = Color(245, 202, 88),
	acRed    = Color(228, 100, 100),
	acOrange = Color(232, 152, 86),
	acPurple = Color(168, 130, 255),
	shadow   = Color(0, 0, 0, 80),
}

-- ── STATE ────────────────────────────────────────────────────────────────

ui.State = ui.State or {
	health = 0, armor = 0, hunger = 0, xp = 0,
	inspectMode = false, f3Held = false,
	hoverRects = {},
	utimeDisabled = false,
	playedShow = 0,
}

-- ── MATERIALS / LOCALS ──────────────────────────────────────────────────

local gradientDown  = Material("gui/gradient_down")
local gradientUp    = Material("gui/gradient_up")
local gradientRight = Material("vgui/gradient-r")
local gradientLeft  = Material("vgui/gradient-l")

local TEXT_ALIGN_LEFT   = TEXT_ALIGN_LEFT
local TEXT_ALIGN_RIGHT  = TEXT_ALIGN_RIGHT
local TEXT_ALIGN_CENTER = TEXT_ALIGN_CENTER
local draw, surface, math, string, table = draw, surface, math, string, table
local pairs, ipairs, hook, timer = pairs, ipairs, hook, timer
local IsValid, Lerp, FrameTime, CurTime = IsValid, Lerp, FrameTime, CurTime
local ColorAlpha, ScrW, ScrH = ColorAlpha, ScrW, ScrH
local input, gui = input, gui

-- ── HIDDEN HUD ELEMENTS ─────────────────────────────────────────────────

local hiddenHudElements = {
	DarkRP_LocalPlayerHUD = true,
	DarkRP_Hungermod      = true,
	DarkRP_Agenda         = true,
	DarkRP_LockdownHUD    = true,
	DarkRP_ArrestedHUD    = true,
	DarkRP_VoiceChat      = true,
}

-- ==========================================================================
-- FONTS
-- ==========================================================================

local function createFonts()
	local function f(name, family, sz, wt)
		surface.CreateFont(name, { font = family, size = sz, weight = wt, antialias = true, extended = true })
	end

	-- HUD
	f("MUI.Title",    "Verdana", 26, 900)
	f("MUI.Name",     "Verdana", 19, 900)
	f("MUI.Body",     "Verdana", 15, 700)
	f("MUI.Small",    "Verdana", 12, 600)
	f("MUI.Badge",    "Verdana", 11, 900)
	f("MUI.Micro",    "Verdana", 10, 700)
	f("MUI.ValLg",    "Verdana", 18, 900)
	f("MUI.ValXL",    "Verdana", 28, 900)
	f("MUI.Tooltip",  "Verdana", 13, 900)

	-- F4 Menu
	f("MUI.F4Nav",     "Tahoma", 13, 700)
	f("MUI.F4Title",   "Tahoma", 24, 900)
	f("MUI.F4Section", "Tahoma", 16, 800)
	f("MUI.F4Item",    "Tahoma", 14, 700)
	f("MUI.F4Meta",    "Tahoma", 12, 600)
	f("MUI.F4Body",    "Tahoma", 14, 600)
	f("MUI.F4Price",   "Tahoma", 14, 900)
	f("MUI.F4Big",     "Tahoma", 20, 900)
	f("MUI.F4Desc",    "Tahoma", 13, 500)

	-- Scoreboard
	f("MUI.SBTitle",   "Tahoma", 24, 900)
	f("MUI.SBSub",     "Tahoma", 13, 600)
	f("MUI.SBHeader",  "Tahoma", 11, 900)
	f("MUI.SBName",    "Tahoma", 14, 800)
	f("MUI.SBInfo",    "Tahoma", 12, 600)
	f("MUI.SBSmall",   "Tahoma", 11, 600)
	f("MUI.SBBig",     "Tahoma", 22, 900)
	f("MUI.SBStatVal", "Verdana", 16, 900)
	f("MUI.SBStatLbl", "Tahoma", 10, 700)
	f("MUI.SBAction",  "Tahoma", 11, 800)
	f("MUI.SBGroup",   "Tahoma", 10, 900)

	-- /played
	f("MUI.PlayTitle", "Tahoma", 18, 900)
	f("MUI.PlayVal",   "Verdana", 22, 900)
	f("MUI.PlayLbl",   "Tahoma", 11, 700)
end

createFonts()

-- ==========================================================================
-- HELPER FUNCTIONS
-- ==========================================================================

local function getPlayerLevel(ply)
	if not IsValid(ply) then return 1 end
	if ply.getLevel then return tonumber(ply:getLevel()) or 1 end
	return tonumber(ply.getDarkRPVar and ply:getDarkRPVar("level")) or 1
end

local function getPlayerXP(ply)
	if not IsValid(ply) then return 0 end
	if ply.getXP then return tonumber(ply:getXP()) or 0 end
	return tonumber(ply.getDarkRPVar and ply:getDarkRPVar("xp")) or 0
end

local function getPlayerMaxXP(ply)
	if not IsValid(ply) then return 100 end
	if ply.getMaxXP then return math.max(tonumber(ply:getMaxXP()) or 0, 1) end
	if OldGoldProgression and OldGoldProgression.GetRequiredXP then
		return math.max(tonumber(OldGoldProgression.GetRequiredXP(getPlayerLevel(ply))) or 0, 1)
	end
	return 100
end

local function formatMoney(amount)
	amount = tonumber(amount) or 0
	if DarkRP and DarkRP.formatMoney then return DarkRP.formatMoney(amount) end
	return "$" .. tostring(amount)
end

local function smoothValue(key, target, speed)
	ui.State[key] = Lerp(FrameTime() * speed, ui.State[key] or 0, target)
	return ui.State[key]
end

local function formatDuration(seconds)
	seconds = math.max(math.floor(tonumber(seconds) or 0), 0)
	local weeks   = math.floor(seconds / 604800); seconds = seconds - weeks * 604800
	local days    = math.floor(seconds / 86400);  seconds = seconds - days * 86400
	local hours   = math.floor(seconds / 3600);   seconds = seconds - hours * 3600
	local minutes = math.floor(seconds / 60);     seconds = seconds - minutes * 60
	return string.format("%02dw %02dd %02dh %02dm %02ds", weeks, days, hours, minutes, seconds)
end

local function styleScrollPanel(scroll)
	local sbar = scroll:GetVBar()
	sbar:SetWide(6)
	sbar.Paint = function() end
	sbar.btnUp.Paint = function() end
	sbar.btnDown.Paint = function() end
	sbar.btnGrip.Paint = function(self, w, h)
		draw.RoundedBox(3, 1, 0, w - 2, h, Color(255, 255, 255, 24))
	end
end

local function setupModelCamera(mdl, modelPath, isPlayerModel)
	mdl:SetModel(modelPath)
	if not IsValid(mdl.Entity) then return end
	mdl:SetAmbientLight(Color(42, 48, 56))
	mdl:SetDirectionalLight(BOX_FRONT, Color(220, 228, 236))
	mdl:SetDirectionalLight(BOX_TOP, Color(255, 255, 255))
	if isPlayerModel then
		mdl:SetFOV(50)
		mdl:SetCamPos(Vector(70, 0, 55))
		mdl:SetLookAt(Vector(0, 0, 55))
	elseif IsValid(mdl.Entity) then
		local mn, mx = mdl.Entity:GetRenderBounds()
		local center = (mn + mx) * 0.5
		local maxDim = math.max(mx.x - mn.x, mx.y - mn.y, mx.z - mn.z, 1)
		mdl:SetFOV(45)
		mdl:SetCamPos(center + Vector(maxDim * 1.8, maxDim * 0.5, maxDim * 0.4))
		mdl:SetLookAt(center)
	end
	mdl.LayoutEntity = function(self, ent)
		ent:SetAngles(Angle(0, RealTime() * 30, 0))
	end
end

local function paintModelFrame(self, w, h, radius)
	draw.RoundedBox(radius or 6, 0, 0, w, h, Color(255, 255, 255, 4))
	self:DrawModel()
	surface.SetDrawColor(255, 255, 255, 8)
	surface.DrawOutlinedRect(0, 0, w, h, 1)
end

local topTierGroups = {
	owner = true,
	founder = true,
	boss = true,
	headadmin = true,
	communityowner = true,
}

local function getAdminTier(ply)
	if not IsValid(ply) then return 0 end
	local group = string.lower((ply.GetUserGroup and ply:GetUserGroup()) or "user")
	if topTierGroups[group] then return 4 end
	if ply:IsSuperAdmin() then return 3 end
	if ply:IsAdmin() or group == "operator" or group == "moderator" then return 2 end
	return 0
end

local function resizeIconLayout(layout, bottomPadding)
	timer.Simple(0, function()
		if not IsValid(layout) then return end
		layout:Layout()
		local bottom = 0
		for _, child in ipairs(layout:GetChildren()) do
			if IsValid(child) then
				bottom = math.max(bottom, child.y + child:GetTall())
			end
		end
		layout:SetTall(bottom + (bottomPadding or 0))
	end)
end

local function isUsableModel(modelPath)
	if not isstring(modelPath) then return false end
	modelPath = string.Trim(modelPath)
	if modelPath == "" or modelPath == "models/error.mdl" then return false end
	return util.IsValidModel(modelPath)
end

local function pickValidModel(...)
	for i = 1, select("#", ...) do
		local candidate = select(i, ...)
		if istable(candidate) then
			for _, nested in ipairs(candidate) do
				local resolved = pickValidModel(nested)
				if resolved then return resolved end
			end
		elseif isUsableModel(candidate) then
			return string.Trim(candidate)
		end
	end
	return nil
end

local function getStoredEntityModel(className)
	if not className or className == "" then return nil end

	local swep = weapons.GetStored(className)
	if swep then
		local model = pickValidModel(swep.WorldModel, swep.WModel, swep.ViewModel, swep.VModel, swep.Model, swep.model)
		if model then return model end
	end

	local sent = scripted_ents.GetStored(className)
	if sent then
		sent = sent.t or sent
		local model = pickValidModel(sent.Model, sent.WorldModel, sent.model)
		if model then return model end
	end

	local weaponList = list.Get("Weapon") or {}
	local spawnableEntities = list.Get("SpawnableEntities") or {}
	local entry = weaponList[className] or spawnableEntities[className]
	if entry then
		return pickValidModel(entry.Model, entry.WorldModel, entry.model)
	end

	return nil
end

local function getAmmoDisplayModel(itemName)
	local lowerName = string.lower(itemName or "")
	if string.find(lowerName, "shot") or string.find(lowerName, "buck") then
		return "models/items/boxbuckshot.mdl"
	end
	if string.find(lowerName, "357") or string.find(lowerName, "revolver") then
		return "models/items/357ammo.mdl"
	end
	if string.find(lowerName, "smg") or string.find(lowerName, "pistol") then
		return "models/items/boxsrounds.mdl"
	end
	if string.find(lowerName, "ar2") or string.find(lowerName, "rifle") or string.find(lowerName, "sniper") then
		return "models/items/combine_rifle_cartridge01.mdl"
	end
	if string.find(lowerName, "cross") then
		return "models/items/crossbowrounds.mdl"
	end
	return "models/items/boxmrounds.mdl"
end

local function getWeaponDisplayData(className)
	local stored = weapons.GetStored(className or "")
	local displayName = className or "Unknown"
	local model = nil
	if stored then
		displayName = stored.PrintName or stored.Name or className or "Unknown"
		model = pickValidModel(stored.WorldModel, stored.WModel, stored.ViewModel, stored.VModel, stored.Model, stored.model)
	end
	if not model then
		model = getStoredEntityModel(className)
	end
	return displayName, model
end

local function runUlxCommand(commandName, targetID, ...)
	local args = { ... }
	local params = { "ulx", commandName }
	if targetID then
		params[#params + 1] = targetID
	end
	for _, value in ipairs(args) do
		if value ~= nil and value ~= "" then
			params[#params + 1] = tostring(value)
		end
	end
	RunConsoleCommand(unpack(params))
end

local function runChatCommand(text)
	if not text or text == "" then return end
	RunConsoleCommand("say", text)
end

local function sendAdminPlayerAction(target, action, amount, reason)
	if not IsValid(target) then return end
	net.Start("MUI_AdminPlayerAction")
	net.WriteEntity(target)
	net.WriteString(action or "")
	net.WriteInt(math.floor(tonumber(amount) or 0), 32)
	net.WriteString(reason or "")
	net.SendToServer()
end

local function confirmAction(title, text, callback)
	Derma_Query(text, title, "Run", function()
		if callback then callback() end
	end, "Cancel")
end

local function promptForNumber(title, message, defaultValue, callback)
	Derma_StringRequest(title, message, tostring(defaultValue or ""), function(value)
		local amount = math.floor(tonumber(value) or 0)
		if callback then callback(amount) end
	end, nil, "Run", "Cancel")
end

local function getInitials(text)
	local letters = {}
	for word in string.gmatch(text or "", "%S+") do
		letters[#letters + 1] = string.upper(string.sub(word, 1, 1))
		if #letters >= 2 then break end
	end
	if #letters == 0 then
		return "?"
	end
	return table.concat(letters)
end

local function createCompactPlaceholder(parent, label, accent)
	local holder = vgui.Create("DPanel", parent)
	holder:SetPos(6, 6)
	holder:SetSize(36, 36)
	holder.Paint = function(self, w, h)
		draw.RoundedBox(6, 0, 0, w, h, Color(255, 255, 255, 6))
		draw.SimpleText(label or "?", "MUI.SBAction", w * 0.5, h * 0.5, accent or ui.Theme.acBlue, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	return holder
end

local function createPreviewPlaceholder(parent, title, subtitle, accent)
	local empty = vgui.Create("DPanel", parent)
	empty:Dock(FILL)
	empty:DockMargin(12, 12, 12, 12)
	empty.Paint = function(self, w, h)
		draw.RoundedBox(6, 0, 0, w, h, Color(255, 255, 255, 4))
		draw.SimpleText(title or "NO PREVIEW", "MUI.F4Section", w * 0.5, h * 0.5 - 12, accent or ui.Theme.acBlue, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(subtitle or "This addon did not expose a usable world model.", "MUI.F4Meta", w * 0.5, h * 0.5 + 12, ui.Theme.sub, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	return empty
end

local function createModelPreviewCard(parent, footerText)
	local footerLabel = footerText or ""

	local card = vgui.Create("DPanel", parent)
	card:Dock(FILL)
	card.Paint = function(self, w, h)
		draw.RoundedBox(6, 0, 0, w, h, Color(255, 255, 255, 5))
		surface.SetDrawColor(255, 255, 255, 8)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
	end

	local footer = vgui.Create("DPanel", card)
	footer:Dock(BOTTOM)
	footer:SetTall(30)
	footer.Paint = function(self, w, h)
		draw.RoundedBoxEx(6, 0, 0, w, h, Color(255, 255, 255, 4), false, false, true, true)
		if footerLabel ~= "" then
			draw.SimpleText(footerLabel, "MUI.SBHeader", 12, h * 0.5, ui.Theme.sub, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end
	end

	local icon = vgui.Create("SpawnIcon", card)
	icon:Dock(FILL)
	icon:DockMargin(14, 14, 14, 10)
	icon:SetTooltip(false)
	icon:SetMouseInputEnabled(false)

	local function setModel(modelPath)
		if not isUsableModel(modelPath) then return false end
		icon:SetModel(modelPath)
		return true
	end

	local function setFooter(text)
		footerLabel = text or ""
	end

	return card, icon, setModel, setFooter
end

local function updateDockedWrapperHeight(wrapper, extraPadding)
	if not IsValid(wrapper) then return end
	wrapper:InvalidateLayout(true)

	timer.Simple(0, function()
		if not IsValid(wrapper) then return end
		local total = 0
		for _, child in ipairs(wrapper:GetChildren()) do
			if child:IsVisible() then
				total = math.max(total, child:GetY() + child:GetTall())
			end
		end
		wrapper:SetTall(total + (extraPadding or 16))
		if IsValid(wrapper:GetParent()) then
			wrapper:GetParent():InvalidateLayout(true)
		end
	end)

	timer.Simple(0.05, function()
		if not IsValid(wrapper) then return end
		local total = 0
		for _, child in ipairs(wrapper:GetChildren()) do
			if child:IsVisible() then
				total = math.max(total, child:GetY() + child:GetTall())
			end
		end
		wrapper:SetTall(total + (extraPadding or 16))
		if IsValid(wrapper:GetParent()) then
			wrapper:GetParent():InvalidateLayout(true)
		end
	end)
end

local function getShopItemPreview(item, tabKey)
	local primaryModel = pickValidModel(item.previewModel, item.model)
	local secondaryModel = nil

	if not primaryModel and item.entityClass then
		primaryModel = getStoredEntityModel(item.entityClass)
	end

	if tabKey == "shipments" then
		secondaryModel = pickValidModel(item.model)
		primaryModel = pickValidModel(item.shipModel, primaryModel, "models/items/item_item_crate.mdl")
	elseif tabKey == "ammo" then
		primaryModel = pickValidModel(primaryModel, getAmmoDisplayModel(item.name))
	end

	return primaryModel, secondaryModel
end

-- ==========================================================================
-- DRAWING HELPERS
-- ==========================================================================

local weaponHints = {
	["weapon_physgun"]    = "LMB Grab  |  RMB Freeze",
	["weapon_physcannon"] = "LMB Punt  |  RMB Grab",
	["gmod_tool"]         = "LMB Primary  |  RMB Secondary",
	["gmod_camera"]       = "LMB Snap  |  RMB Zoom",
}

local function drawHudPanel(x, y, w, h, accent)
	draw.RoundedBox(10, x, y, w, h, ColorAlpha(ui.Theme.bg, 78))
	draw.RoundedBox(9, x + 2, y + 2, w - 4, h - 4, ColorAlpha(ui.Theme.surface, 56))
	surface.SetMaterial(gradientUp)
	surface.SetDrawColor(255, 255, 255, 3)
	surface.DrawTexturedRect(x, y, w, math.floor(h * 0.5))
	if accent then
		surface.SetDrawColor(ColorAlpha(accent, 200))
		surface.DrawRect(x + 10, y + 10, math.max(math.floor(w * 0.18), 34), 2)
	end
end

local function drawBar(x, y, w, h, progress, color)
	progress = math.Clamp(progress, 0, 1)
	draw.RoundedBox(math.floor(h * 0.5), x, y, w, h, Color(255, 255, 255, 18))
	if progress > 0 then
		local fw = math.max(math.floor(w * progress), h)
		draw.RoundedBox(math.floor(h * 0.5), x, y, fw, h, ColorAlpha(color, 210))
		surface.SetMaterial(gradientRight)
		surface.SetDrawColor(255, 255, 255, 30)
		surface.DrawTexturedRect(x, y, fw, h)
	end
end

local function drawMagColumns(x, y, count, capacity)
	capacity = math.max(tonumber(capacity) or 1, 1)
	count = math.Clamp(tonumber(count) or 0, 0, capacity)
	local cols = math.Clamp(capacity, 1, 12)
	local filled = math.Clamp(math.ceil((count / capacity) * cols), 0, cols)
	local gap = cols <= 8 and 8 or 6
	local colW = gap - 3
	for i = 1, cols do
		local cx = x + (i - 1) * gap
		local tall = (i % 2 == 0) and 16 or 12
		local off = (i % 2 == 0) and 0 or 4
		local c = i <= filled and ui.Theme.acGold or Color(255, 255, 255, 20)
		local a = i <= filled and 240 or 120
		draw.RoundedBox(2, cx, y + off, colW, tall, ColorAlpha(c, a))
	end
end

local function drawGlassPanel(x, y, w, h, radius, accent)
	draw.RoundedBox(radius or 14, x, y, w, h, ui.Theme.bg)
	draw.RoundedBox((radius or 14) - 1, x + 1, y + 1, w - 2, h - 2, ui.Theme.surface)
	surface.SetMaterial(gradientUp)
	surface.SetDrawColor(255, 255, 255, 4)
	surface.DrawTexturedRect(x + 1, y + 1, w - 2, math.floor(h * 0.3))
	if accent then
		surface.SetDrawColor(accent.r, accent.g, accent.b, 50)
		surface.DrawRect(x, y, w, 2)
	end
end

local function registerHoverRect(id, x, y, w, h, data)
	ui.State.hoverRects[id] = { x = x, y = y, w = w, h = h, data = data }
end

local function getHoveredRect()
	if not ui.State.inspectMode then return nil end
	local mx, my = gui.MousePos()
	for _, r in pairs(ui.State.hoverRects) do
		if mx >= r.x and mx <= r.x + r.w and my >= r.y and my <= r.y + r.h then
			return r
		end
	end
	return nil
end

local function drawHoverTooltip(rect)
	if not rect or not rect.data then return end
	local mx, my = gui.MousePos()
	local w, h = 220, 92
	local x = math.min(mx + 16, ScrW() - w - 16)
	local y = math.min(my + 16, ScrH() - h - 16)
	local d = rect.data
	drawHudPanel(x, y, w, h, d.color or ui.Theme.acBlue)
	draw.SimpleText(d.title or "Info", "MUI.Tooltip", x + 12, y + 10, ui.Theme.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	draw.SimpleText(d.line1 or "", "MUI.Small", x + 12, y + 34, ui.Theme.sub, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	draw.SimpleText(d.line2 or "", "MUI.Small", x + 12, y + 50, ui.Theme.sub, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	if d.line3 and d.line3 ~= "" then
		draw.SimpleText(d.line3, "MUI.Small", x + 12, y + 66, ui.Theme.sub, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	end
end

local function updateInspectMode()
	local down = input.IsKeyDown(KEY_F3)
	if down and not ui.State.f3Held then
		ui.State.inspectMode = not ui.State.inspectMode
		gui.EnableScreenClicker(ui.State.inspectMode)
	end
	ui.State.f3Held = down
	if ui.State.inspectMode and not system.HasFocus() then
		ui.State.inspectMode = false
		gui.EnableScreenClicker(false)
	end
end

-- ==========================================================================
-- WEAPON INFO
-- ==========================================================================

local function getWeaponInfo(ply)
	local wep = IsValid(ply) and ply:GetActiveWeapon() or nil
	if not IsValid(wep) then
		return { name = "Unarmed", hasAmmo = false, hint = "", clip = 0, reserve = 0, clipSize = 0 }
	end
	local class = wep:GetClass()
	local name = wep.GetPrintName and wep:GetPrintName() or class
	if not name or name == "" or name:sub(1, 1) == "#" then name = class end
	local clip = wep:Clip1()
	local ammoType = wep:GetPrimaryAmmoType()
	local reserve = ammoType >= 0 and ply:GetAmmoCount(ammoType) or 0
	local clipSize = 0
	if wep.Primary and tonumber(wep.Primary.ClipSize) and tonumber(wep.Primary.ClipSize) > 0 then
		clipSize = tonumber(wep.Primary.ClipSize)
	elseif wep.GetMaxClip1 then
		clipSize = tonumber(wep:GetMaxClip1()) or 0
	end
	if clip >= 0 and clipSize <= 0 then clipSize = math.max(clip, 1) end
	local hasAmmo = clip >= 0 or (ammoType >= 0 and reserve > 0)
	return { name = name, hasAmmo = hasAmmo, clip = clip, reserve = reserve, clipSize = clipSize, hint = weaponHints[class] or "" }
end

-- ==========================================================================
-- OVERLAY PANELS
-- ==========================================================================

local function drawAgenda(ply)
	local agenda = ply.getAgendaTable and ply:getAgendaTable() or nil
	if not agenda then return end
	local agendaText = ply.getDarkRPVar and ply:getDarkRPVar("agenda") or ""
	if not agendaText or agendaText == "" then return end
	local text = string.gsub(string.gsub(agendaText, "//", "\n"), "\\n", "\n")
	text = DarkRP and DarkRP.textWrap and DarkRP.textWrap(text, "MUI.Small", 380) or text
	local x, y = 34, 34
	local w = math.min(ScrW() * 0.24, 350)
	drawHudPanel(x, y, w, 108, ui.Theme.acCyan)
	draw.SimpleText("AGENDA", "MUI.Micro", x + 12, y + 10, ui.Theme.acCyan, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	draw.SimpleText(agenda.Title or "Agenda", "MUI.Body", x + 12, y + 24, ui.Theme.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	draw.SimpleText(text, "MUI.Small", x + 12, y + 46, ui.Theme.sub, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end

local function drawStateBanner(ply)
	local parts = {}
	if GetGlobalBool("DarkRP_LockDown") then
		parts[#parts + 1] = { text = DarkRP and DarkRP.getPhrase and DarkRP.getPhrase("lockdown_started") or "Lockdown in progress", color = ui.Theme.acRed }
	end
	if ply.getDarkRPVar and ply:getDarkRPVar("Arrested") then
		parts[#parts + 1] = { text = DarkRP and DarkRP.getPhrase and DarkRP.getPhrase("youre_arrested", "") or "You are arrested", color = ui.Theme.acOrange }
	elseif ply.getDarkRPVar and ply:getDarkRPVar("wanted") then
		local reason = tostring(ply:getDarkRPVar("wantedReason") or "Wanted")
		parts[#parts + 1] = { text = "Wanted: " .. reason, color = ui.Theme.acRed }
	end
	if #parts == 0 then return end
	local banner = parts[1]
	local btext = string.upper(banner.text)
	surface.SetFont("MUI.Badge")
	local tw = surface.GetTextSize(btext)
	local pw = tw + 28
	local x = ScrW() * 0.5 - pw * 0.5
	drawHudPanel(x, 26, pw, 28, banner.color)
	draw.SimpleText(btext, "MUI.Badge", x + pw * 0.5, 34, banner.color, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end

local function drawMediaOverlay()
	if not wyozimc or not wyozimc.ShowPlayingHUD then return end
	local mc = wyozimc.MainContainer
	if not mc or (mc.has_flag and mc:has_flag(wyozimc.FLAG_NO_HUD)) then return end
	local pd = mc.play_data
	local qd = pd and pd.query_data or nil
	if not qd then return end
	local progress = mc.get_played_fraction and mc:get_played_fraction() or 0
	local elapsed = pd.started and (CurTime() - pd.started) or 0
	local timeText = wyozimc.FormatTime and wyozimc.FormatTime(elapsed) or "0:00"
	if qd.Duration and qd.Duration ~= -1 and wyozimc.FormatTime then
		timeText = timeText .. " / " .. wyozimc.FormatTime(qd.Duration)
	end
	local w = math.min(ScrW() * 0.22, 320)
	local x = ScrW() - w - 34
	drawHudPanel(x, 34, w, 52, ui.Theme.acCyan)
	draw.SimpleText("MEDIA", "MUI.Micro", x + 12, 42, ui.Theme.acCyan, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	draw.SimpleText(qd.Title or "Now playing", "MUI.Body", x + 12, 56, ui.Theme.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	draw.SimpleText(timeText, "MUI.Micro", x + w - 12, 44, ui.Theme.sub, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
	drawBar(x + 12, 72, w - 24, 6, progress, ui.Theme.acCyan)
end

-- ==========================================================================
-- /PLAYED FLOATING PANEL
-- ==========================================================================

local function drawPlayedPanel(ply, alpha)
	if not IsValid(ply) or not ply.GetUTimeTotalTime or not ply.GetUTimeSessionTime then return end
	local sw = ScrW()
	local panelW, panelH = 280, 120
	local px = math.floor(sw * 0.5 - panelW * 0.5)
	local py = 40
	local a = math.floor(alpha)
	draw.RoundedBox(12, px, py, panelW, panelH, ColorAlpha(ui.Theme.bg, a))
	draw.RoundedBox(11, px + 1, py + 1, panelW - 2, panelH - 2, ColorAlpha(ui.Theme.surface, math.floor(a * 0.9)))
	surface.SetDrawColor(ui.Theme.acCyan.r, ui.Theme.acCyan.g, ui.Theme.acCyan.b, math.floor(a * 0.6))
	surface.DrawRect(px, py, panelW, 2)
	draw.SimpleText("YOUR PLAY TIME", "MUI.PlayTitle", px + panelW * 0.5, py + 14, ColorAlpha(ui.Theme.text, a), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	draw.SimpleText(formatDuration(ply:GetUTimeTotalTime()), "MUI.PlayVal", px + panelW * 0.5, py + 38, ColorAlpha(ui.Theme.acCyan, a), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	draw.SimpleText("TOTAL", "MUI.PlayLbl", px + panelW * 0.5, py + 63, ColorAlpha(ui.Theme.sub, a), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	surface.SetDrawColor(255, 255, 255, math.floor(a * 0.04))
	surface.DrawRect(px + 40, py + 80, panelW - 80, 1)
	draw.SimpleText(formatDuration(ply:GetUTimeSessionTime()), "MUI.PlayVal", px + panelW * 0.5, py + 86, ColorAlpha(ui.Theme.text, a), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	draw.SimpleText("THIS SESSION", "MUI.PlayLbl", px + panelW * 0.5, py + 111, ColorAlpha(ui.Theme.sub, math.floor(a * 0.8)), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end

-- ==========================================================================
-- MAIN HUD
-- ==========================================================================

local function drawHUD()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	if OldGoldProgression and OldGoldProgression.Config then
		OldGoldProgression.Config.hudEnabled = false
	end
	hook.Remove("HUDPaint", "OldGoldProgression_HUD")
	hook.Remove("HUDPaint", "WyoziMCDefaultHUD")
	ui.State.hoverRects = {}

	if not ui.State.utimeDisabled and GetConVar("utime_enable") then
		RunConsoleCommand("utime_enable", "0")
		ui.State.utimeDisabled = true
	end

	local sw, sh = ScrW(), ScrH()
	local health = math.max(ply:Health(), 0)
	local maxHP  = math.max(ply:GetMaxHealth(), 1)
	local armor  = math.max(ply:Armor(), 0)
	local level  = getPlayerLevel(ply)
	local xp     = getPlayerXP(ply)
	local maxXP  = getPlayerMaxXP(ply)
	local job    = tostring(ply.getDarkRPVar and ply:getDarkRPVar("job") or team.GetName(ply:Team()) or "Citizen")
	local money  = tonumber(ply.getDarkRPVar and ply:getDarkRPVar("money")) or 0
	local salary = tonumber(ply.getDarkRPVar and ply:getDarkRPVar("salary")) or 0

	local hpProg = smoothValue("health", health / maxHP, 10)
	local arProg = smoothValue("armor", armor / 100, 10)
	local xpProg = smoothValue("xp", maxXP > 0 and xp / maxXP or 0, 10)
	local wep = getWeaponInfo(ply)

	local lx, barW, barH, lblW = 24, 150, 8, 24
	local idY = sh - 118
	draw.SimpleText(string.upper(job), "MUI.Micro", lx, idY, ui.Theme.sub)
	draw.SimpleText(formatMoney(money), "MUI.ValLg", lx, idY + 14, ui.Theme.acGold)
	draw.SimpleText("SALARY " .. formatMoney(salary), "MUI.Micro", lx, idY + 35, ui.Theme.sub)
	surface.SetDrawColor(255, 255, 255, 12)
	surface.DrawRect(lx, sh - 72, barW + lblW + 30, 1)
	local hpY = sh - 62
	draw.SimpleText("HP", "MUI.Micro", lx, hpY + 1, ui.Theme.sub)
	drawBar(lx + lblW, hpY, barW, barH, hpProg, ui.Theme.acGreen)
	draw.SimpleText(tostring(health), "MUI.Small", lx + lblW + barW + 8, hpY - 1, ui.Theme.text)
	local nextY = hpY + 18
	draw.SimpleText("AR", "MUI.Micro", lx, nextY + 1, ui.Theme.sub)
	drawBar(lx + lblW, nextY, barW, barH, arProg, ui.Theme.acBlue)
	draw.SimpleText(tostring(armor), "MUI.Small", lx + lblW + barW + 8, nextY - 1, ui.Theme.text)
	nextY = nextY + 18

	local hungerEnabled = not (DarkRP and DarkRP.disabledDefaults and DarkRP.disabledDefaults["modules"] and DarkRP.disabledDefaults["modules"]["hungermod"])
	if hungerEnabled then
		local hunger  = math.Clamp(tonumber(ply.getDarkRPVar and ply:getDarkRPVar("Energy")) or 0, 0, 100)
		local hunProg = smoothValue("hunger", hunger / 100, 10)
		draw.SimpleText("EN", "MUI.Micro", lx, nextY + 1, ui.Theme.sub)
		drawBar(lx + lblW, nextY, barW, barH, hunProg, ui.Theme.acOrange)
		draw.SimpleText(tostring(hunger) .. "%", "MUI.Small", lx + lblW + barW + 8, nextY - 1, ui.Theme.text)
	end

	local xpW = 340
	local xpX = math.floor(sw * 0.5 - xpW * 0.5)
	local xpY = sh - 18
	draw.SimpleText("LVL " .. tostring(level), "MUI.Micro", xpX, xpY - 13, ui.Theme.sub)
	draw.SimpleText(tostring(xp) .. " / " .. tostring(maxXP), "MUI.Micro", xpX + xpW, xpY - 13, ui.Theme.sub, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
	drawBar(xpX, xpY, xpW, 5, xpProg, ui.Theme.acCyan)
	registerHoverRect("xp", xpX, xpY - 16, xpW, 26, {
		title = "Progression", line1 = "Level " .. tostring(level),
		line2 = tostring(xp) .. " / " .. tostring(maxXP) .. " XP",
		line3 = tostring(math.max(maxXP - xp, 0)) .. " XP to next level",
		color = ui.Theme.acCyan,
	})

	local rx = sw - 24
	if wep.hasAmmo then
		local wy = sh - 92
		draw.SimpleText(wep.name, "MUI.Small", rx, wy, ui.Theme.sub, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
		if wep.clip >= 0 then
			local divX = rx - 48
			draw.SimpleText(tostring(wep.clip), "MUI.ValXL", divX - 4, wy + 16, ui.Theme.text, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
			draw.SimpleText("/", "MUI.Body", divX + 2, wy + 24, Color(255, 255, 255, 35), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			draw.SimpleText(tostring(math.max(wep.reserve, 0)), "MUI.ValLg", rx, wy + 22, ui.Theme.sub, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
		else
			draw.SimpleText(tostring(wep.reserve), "MUI.ValXL", rx, wy + 16, ui.Theme.text, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
		end
		if wep.clip >= 0 and wep.clipSize > 0 then
			local cols = math.Clamp(wep.clipSize, 1, 12)
			local gap  = cols <= 8 and 8 or 6
			local magW = (cols - 1) * gap + (gap - 3)
			drawMagColumns(rx - magW, wy + 52, wep.clip, wep.clipSize)
		end
	elseif wep.name ~= "Unarmed" then
		local wy = sh - 72
		draw.SimpleText(wep.name, "MUI.Body", rx, wy, ui.Theme.text, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
		if wep.hint ~= "" then
			draw.SimpleText(wep.hint, "MUI.Micro", rx, wy + 20, ui.Theme.sub, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
		end
	end
	draw.SimpleText(tostring(ply:Ping()) .. " ms", "MUI.Micro", rx, sh - 18, Color(255, 255, 255, 45), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

	drawAgenda(ply)
	drawStateBanner(ply)
	drawMediaOverlay()

	if ui.State.playedShow > 0 then
		local elapsed = CurTime() - ui.State.playedShow
		local alpha = 0
		if elapsed < 0.5 then alpha = (elapsed / 0.5) * 255
		elseif elapsed < 29.5 then alpha = 255
		elseif elapsed < 30 then alpha = ((30 - elapsed) / 0.5) * 255
		else ui.State.playedShow = 0 end
		if alpha > 0 then drawPlayedPanel(ply, alpha) end
	end

	if ui.State.inspectMode then
		draw.SimpleText("F3 INSPECT", "MUI.Badge", sw * 0.5, sh - 48, ui.Theme.acCyan, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		local hovered = getHoveredRect()
		if hovered then drawHoverTooltip(hovered) end
	end
end

-- ==========================================================================
-- SCOREBOARD (Full Featured - List/Detail Two-Panel)
-- ==========================================================================

local groupColors = {
	owner      = { col = Color(255, 104, 104), label = "OWNER" },
	boss       = { col = Color(255, 104, 104), label = "BOSS" },
	founder    = { col = Color(255, 104, 104), label = "FOUNDER" },
	headadmin  = { col = Color(255, 140, 92), label = "HEAD ADMIN" },
	superadmin = { col = Color(228, 100, 100), label = "SUPERADMIN" },
	admin      = { col = Color(245, 202, 88), label = "ADMIN" },
	operator   = { col = Color(108, 195, 126), label = "OPERATOR" },
	moderator  = { col = Color(168, 130, 255), label = "MODERATOR" },
	vip        = { col = Color(86, 228, 220), label = "VIP" },
	donator    = { col = Color(86, 228, 220), label = "DONATOR" },
}

local quickCommandButtons = {
	{ name = "PROFILE", chat = function(ply) return "!profile " .. tostring(ply:SteamID()) end, color = Color(86, 228, 220) },
	{ name = "DONATE", chat = function() return "!donate" end, color = Color(168, 130, 255) },
	{ name = "SERVER INFO", chat = function() return "!info" end, color = Color(108, 195, 126) },
	{ name = "PLAYED", chat = function() return "/played" end, color = Color(88, 166, 255) },
}

local adminActionSections = {
	{
		title = "Movement",
		minTier = 2,
		buttons = {
			{ name = "GOTO", cmd = "goto", color = Color(86, 228, 220) },
			{ name = "BRING", cmd = "bring", color = Color(86, 228, 220) },
			{ name = "RETURN", cmd = "return", color = Color(86, 228, 220) },
			{ name = "FBRING", cmd = "fbring", color = Color(88, 166, 255) },
			{ name = "F-TP", cmd = "fteleport", color = Color(88, 166, 255) },
		}
	},
	{
		title = "Moderation",
		minTier = 2,
		buttons = {
			{ name = "FREEZE", cmd = "freeze", color = Color(88, 166, 255) },
			{ name = "SLAY", cmd = "slay", color = Color(228, 100, 100), confirm = true },
			{ name = "KICK", cmd = "kick", color = Color(232, 152, 86), confirm = true },
			{ name = "BAN 1H", cmd = "ban", args = { "60" }, color = Color(228, 100, 100), confirm = true },
			{ name = "BAN 1D", cmd = "ban", args = { "1440" }, color = Color(228, 100, 100), confirm = true },
			{ name = "BAN 1W", cmd = "ban", args = { "10080" }, color = Color(228, 100, 100), confirm = true },
			{ name = "BAN P", cmd = "ban", args = { "0" }, color = Color(228, 100, 100), confirm = true },
			{ name = "JAIL", cmd = "jail", color = Color(232, 152, 86) },
			{ name = "UNJAIL", cmd = "unjail", color = Color(232, 152, 86) },
			{ name = "MUTE", cmd = "mute", color = Color(245, 202, 88) },
			{ name = "GAG", cmd = "gag", color = Color(245, 202, 88) },
			{ name = "PGAG", cmd = "pgag", color = Color(245, 202, 88) },
			{ name = "UNPGAG", cmd = "unpgag", color = Color(108, 195, 126) },
		}
	},
	{
		title = "Player Tools",
		minTier = 2,
		buttons = {
			{ name = "PROFILE", cmd = "profile", color = Color(86, 228, 220) },
			{ name = "RESPAWN", cmd = "forcerespawn", color = Color(108, 195, 126) },
			{ name = "ENTER", cmd = "enter", color = Color(168, 130, 255) },
			{ name = "EXIT", cmd = "exit", color = Color(168, 130, 255) },
			{ name = "GOD", cmd = "god", color = Color(108, 195, 126) },
			{ name = "NOCLIP", cmd = "noclip", color = Color(168, 130, 255) },
			{ name = "EXPLODE", cmd = "explode", color = Color(232, 152, 86), confirm = true },
			{ name = "LAUNCH", cmd = "launch", color = Color(88, 166, 255) },
			{ name = "AMMO+", cmd = "giveammo", args = { "120" }, color = Color(245, 202, 88) },
			{ name = "SET AMMO", cmd = "setammo", args = { "999" }, color = Color(245, 202, 88) },
		}
	},
	{
		title = "Economy & Progression",
		minTier = 2,
		buttons = {
			{ name = "ADD XP", netAction = "add_xp", color = Color(86, 228, 220), prompt = function(ply)
				promptForNumber("Add XP", "XP to add to " .. ply:Nick(), 100, function(value)
					if value > 0 then sendAdminPlayerAction(ply, "add_xp", value, "Scoreboard staff action") end
				end)
			end },
			{ name = "TAKE XP", netAction = "remove_xp", color = Color(232, 152, 86), prompt = function(ply)
				promptForNumber("Remove XP", "XP to remove from " .. ply:Nick(), 100, function(value)
					if value > 0 then sendAdminPlayerAction(ply, "remove_xp", value) end
				end)
			end },
			{ name = "SET XP", netAction = "set_xp", color = Color(88, 166, 255), prompt = function(ply)
				promptForNumber("Set XP", "Raw XP value for " .. ply:Nick() .. " at their current level", getPlayerXP(ply), function(value)
					sendAdminPlayerAction(ply, "set_xp", math.max(value, 0))
				end)
			end },
			{ name = "SET LVL", netAction = "set_level", color = Color(168, 130, 255), prompt = function(ply)
				promptForNumber("Set Level", "Level to assign to " .. ply:Nick(), getPlayerLevel(ply), function(value)
					sendAdminPlayerAction(ply, "set_level", math.max(value, 1))
				end)
			end },
			{ name = "ADD $", netAction = "add_money", color = Color(245, 202, 88), prompt = function(ply)
				promptForNumber("Add Money", "Amount to add to " .. ply:Nick(), 1000, function(value)
					if value ~= 0 then sendAdminPlayerAction(ply, "add_money", math.abs(value)) end
				end)
			end },
			{ name = "TAKE $", netAction = "add_money", color = Color(228, 100, 100), prompt = function(ply)
				promptForNumber("Remove Money", "Amount to remove from " .. ply:Nick(), 1000, function(value)
					if value ~= 0 then sendAdminPlayerAction(ply, "add_money", -math.abs(value)) end
				end)
			end },
			{ name = "SET $", netAction = "set_money", color = Color(108, 195, 126), prompt = function(ply)
				local currentMoney = tonumber(ply.getDarkRPVar and ply:getDarkRPVar("money")) or 0
				promptForNumber("Set Money", "Wallet amount for " .. ply:Nick(), currentMoney, function(value)
					sendAdminPlayerAction(ply, "set_money", math.max(value, 0))
				end)
			end },
			{ name = "PAY $", netAction = "give_money", color = Color(86, 228, 220), prompt = function(ply)
				promptForNumber("Transfer Money", "Amount to transfer from your wallet to " .. ply:Nick(), 1000, function(value)
					if value > 0 then sendAdminPlayerAction(ply, "give_money", value) end
				end)
			end },
		}
	},
	{
		title = "Superadmin",
		minTier = 3,
		buttons = {
			{ name = "ADMINMODE", cmd = "administrate", color = Color(108, 195, 126), selfTarget = true },
			{ name = "DBAN", cmd = "dban", color = Color(232, 152, 86), confirm = true },
			{ name = "SBAN 1D", cmd = "sban", args = { "1440" }, color = Color(228, 100, 100), confirm = true },
			{ name = "GBAN", cmd = "gban", color = Color(255, 104, 104), confirm = true },
			{ name = "COPY IP", cmd = "ip", color = Color(168, 130, 255) },
			{ name = "PGAG LIST", cmd = "printpgags", color = Color(86, 228, 220), selfTarget = true },
		}
	},
	{
		title = "Owner",
		minTier = 4,
		buttons = {
			{ name = "FAKEBAN", cmd = "fakeban", args = { "0" }, color = Color(255, 104, 104), confirm = true },
			{ name = "CRASH", cmd = "crash", color = Color(255, 104, 104), confirm = true },
		}
	},
}

local commandReferenceSections = {
	{
		title = "Player Aliases",
		minTier = 0,
		lines = function(ply)
			return {
				"!profile " .. tostring(ply:SteamID()) .. "  opens a profile panel for the selected player",
				"!donate  opens the donation menu",
				"!info  shows server info and connected players",
				"/played  shows your current playtime summary",
			}
		end,
	},
	{
		title = "Admin Surface",
		minTier = 2,
		lines = function(ply)
			local targetID = "#" .. tostring(ply:UserID())
			return {
				"ulx goto/bring/return/fbring/fteleport " .. targetID,
				"ulx jail/unjail/mute/gag/pgag/unpgag " .. targetID,
				"ulx forcerespawn/enter/exit/profile/giveammo/setammo " .. targetID,
				"Scoreboard also exposes direct staff controls for XP, level, money set/add/take, and wallet-to-player transfers.",
			}
		end,
	},
	{
		title = "Superadmin Surface",
		minTier = 3,
		lines = function(ply)
			local targetID = "#" .. tostring(ply:UserID())
			return {
				"ulx administrate, ulx printpgags, ulx ip " .. targetID,
				"ulx sban/dban/gban " .. targetID .. " and utility globals like maprestart/resetmap/timescale",
				"ulx sendlua/url/convar/runscript remain available as console-side power tools",
			}
		end,
	},
	{
		title = "Owner Notes",
		minTier = 4,
		lines = function(ply)
			local targetID = "#" .. tostring(ply:UserID())
			return {
				"Owner-only destructive tools stay behind confirmation: ulx crash " .. targetID .. ", ulx fakeban " .. targetID,
				"For global owner tasks, use ulx sendlua, ulx url, ulx convar, ulx runscript from console or xgui",
			}
		end,
	},
}

local function createScoreboard()
	if IsValid(ui.ScorePanel) then ui.ScorePanel:Remove() end

	local sw, sh = ScrW(), ScrH()
	local pw = math.Clamp(math.floor(sw * 0.68), 750, 1200)
	local ph = math.Clamp(math.floor(sh * 0.78), 500, 900)

	local panel = vgui.Create("DPanel")
	panel:SetSize(pw, ph)
	panel:Center()
	panel:MakePopup()
	panel:SetKeyboardInputEnabled(false)
	panel:SetMouseInputEnabled(true)
	panel._mode = "list"
	panel._selectedPlayer = nil
	panel._lastRefresh = 0
	panel._mouse4Held = false

	-- Main panel paint
	panel.Paint = function(self, w, h)
		draw.RoundedBox(8, 0, 0, w, h, ui.Theme.bg)
		draw.RoundedBox(7, 1, 1, w - 2, h - 2, ui.Theme.surface)
		surface.SetDrawColor(ui.Theme.acBlue.r, ui.Theme.acBlue.g, ui.Theme.acBlue.b, 60)
		surface.DrawRect(0, 0, w, 2)
		surface.SetMaterial(gradientUp)
		surface.SetDrawColor(ui.Theme.acBlue.r, ui.Theme.acBlue.g, ui.Theme.acBlue.b, 6)
		surface.DrawTexturedRect(1, 1, w - 2, 60)
	end

	-- HEADER
	local header = vgui.Create("DPanel", panel)
	header:Dock(TOP)
	header:SetTall(76)
	header.Paint = function(self, w, h)
		draw.SimpleText(GetHostName(), "MUI.SBTitle", 28, 12, ui.Theme.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		draw.SimpleText(tostring(#player.GetAll()) .. " / " .. tostring(game.MaxPlayers()), "MUI.SBTitle", w - 28, 12, ui.Theme.acBlue, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
		draw.SimpleText(game.GetMap(), "MUI.SBSub", 28, 40, ui.Theme.sub, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		draw.SimpleText("DarkRP", "MUI.SBSub", w - 28, 40, ui.Theme.muted, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
		surface.SetDrawColor(255, 255, 255, 8)
		surface.DrawRect(28, h - 1, w - 56, 1)
	end

	-- CONTENT
	local content = vgui.Create("DPanel", panel)
	content:Dock(FILL)
	content.Paint = function() end

	-- ── LIST VIEW ──
	local listView = vgui.Create("DPanel", content)
	listView:Dock(FILL)
	listView:DockMargin(16, 8, 16, 16)
	listView.Paint = function() end

	local colHeader = vgui.Create("DPanel", listView)
	colHeader:Dock(TOP)
	colHeader:SetTall(22)
	colHeader.Paint = function(self, w, h)
		draw.SimpleText("PLAYER", "MUI.SBHeader", 48, h * 0.5, ui.Theme.muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText("JOB", "MUI.SBHeader", math.floor(w * 0.44), h * 0.5, ui.Theme.muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText("LVL", "MUI.SBHeader", math.floor(w * 0.70), h * 0.5, ui.Theme.muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText("PING", "MUI.SBHeader", w - 12, h * 0.5, ui.Theme.muted, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
	end

	local listScroll = vgui.Create("DScrollPanel", listView)
	listScroll:Dock(FILL)
	listScroll:DockMargin(0, 4, 0, 0)
	styleScrollPanel(listScroll)

	panel._listView = listView
	panel._listScroll = listScroll

	-- ── DETAIL VIEW ──
	local detailView = vgui.Create("DPanel", content)
	detailView:Dock(FILL)
	detailView:DockMargin(16, 8, 16, 16)
	detailView.Paint = function() end
	detailView:Hide()

	local backBtn = vgui.Create("DButton", detailView)
	backBtn:Dock(TOP)
	backBtn:SetTall(28)
	backBtn:SetText("")
	backBtn.Paint = function(self, w, h)
		local hv = self:IsHovered()
		draw.RoundedBox(4, 0, 0, 80, h, hv and Color(255, 255, 255, 14) or Color(255, 255, 255, 6))
		draw.SimpleText("<  BACK", "MUI.SBAction", 40, h * 0.5, hv and ui.Theme.text or ui.Theme.sub, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	backBtn.DoClick = function()
		panel._mode = "list"
		listView:Show()
		detailView:Hide()
	end

	local detailScroll = vgui.Create("DScrollPanel", detailView)
	detailScroll:Dock(FILL)
	detailScroll:DockMargin(0, 6, 0, 0)
	styleScrollPanel(detailScroll)

	panel._detailView = detailView
	panel._detailScroll = detailScroll

	-- ── BUILD DETAIL CONTENT ──
	function panel:BuildDetailContent(ply)
		local scrl = self._detailScroll
		scrl:Clear()
		if not IsValid(ply) then return end

		local me = LocalPlayer()
		local adminTier = getAdminTier(me)
		local pSID = ply:SteamID()
		local pSID64 = ply:SteamID64()
		local targetID = "#" .. tostring(ply:UserID())

		local function addSectionHeader(title, subtitle)
			local hdr = vgui.Create("DPanel", scrl)
			hdr:Dock(TOP)
			hdr:SetTall(subtitle and 34 or 26)
			hdr:DockMargin(0, 10, 0, 4)
			hdr.Paint = function(self, w, h)
				draw.SimpleText(title, "MUI.SBHeader", 0, 2, ui.Theme.muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				if subtitle then
					draw.SimpleText(subtitle, "MUI.SBSmall", w, 2, ui.Theme.sub, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
				end
				surface.SetDrawColor(255, 255, 255, 8)
				surface.DrawRect(0, h - 1, w, 1)
			end
			return hdr
		end

		local hero = vgui.Create("DPanel", scrl)
		hero:Dock(TOP)
		hero:SetTall(156)
		hero.Paint = function(self, w, h)
			draw.RoundedBox(6, 0, 0, w, h, Color(255, 255, 255, 4))
			local pName = ply:Nick()
			local pGroup = string.lower((ply.GetUserGroup and ply:GetUserGroup()) or "user")
			local grpInfo = groupColors[pGroup]
			local teamColor = team.GetColor(ply:Team()) or Color(200, 210, 220)
			local pJob = (ply.getDarkRPVar and ply:getDarkRPVar("job")) or team.GetName(ply:Team()) or "Unknown"
			draw.SimpleText(pName, "MUI.SBBig", 92, 16, teamColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			if grpInfo then
				surface.SetFont("MUI.SBGroup")
				local tw = surface.GetTextSize(grpInfo.label)
				draw.RoundedBox(4, 92, 46, tw + 12, 18, ColorAlpha(grpInfo.col, 28))
				draw.SimpleText(grpInfo.label, "MUI.SBGroup", 98, 51, grpInfo.col, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			end
			draw.SimpleText(pSID, "MUI.SBSub", 92, 72, ui.Theme.sub, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			draw.SimpleText(pJob, "MUI.SBInfo", 92, 92, ui.Theme.muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			draw.SimpleText("TEAM " .. tostring(ply:Team()), "MUI.SBSmall", 92, 114, ColorAlpha(teamColor, 190), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		end

		local av = vgui.Create("AvatarImage", hero)
		av:SetSize(64, 64)
		av:SetPos(14, 16)
		av:SetPlayer(ply, 184)

		local mdl = vgui.Create("DModelPanel", hero)
		mdl:SetSize(210, 132)
		mdl:SetPos(hero:GetWide() - 224, 12)
		mdl:SetFOV(46)
		mdl.Paint = function(self, w, h)
			paintModelFrame(self, w, h, 6)
		end
		mdl.PerformLayout = function(self)
			self:SetPos(hero:GetWide() - self:GetWide() - 12, 12)
		end
		setupModelCamera(mdl, ply:GetModel(), true)
		mdl._muiModel = ply:GetModel()
		mdl.Think = function(self)
			if not IsValid(ply) then return end
			local currentModel = ply:GetModel()
			if currentModel ~= self._muiModel then
				self._muiModel = currentModel
				setupModelCamera(self, currentModel, true)
			end
		end

		local statsRow = vgui.Create("DPanel", scrl)
		statsRow:Dock(TOP)
		statsRow:SetTall(56)
		statsRow:DockMargin(0, 8, 0, 0)
		statsRow.Paint = function(self, w, h)
			local stats = {
				{ label = "LEVEL", value = tostring(getPlayerLevel(ply)), color = ui.Theme.acCyan },
				{ label = "MONEY", value = formatMoney(tonumber(ply.getDarkRPVar and ply:getDarkRPVar("money")) or 0), color = ui.Theme.acGold },
				{ label = "HEALTH", value = tostring(math.max(ply:Health(), 0)), color = ui.Theme.acGreen },
				{ label = "ARMOR", value = tostring(math.max(ply:Armor(), 0)), color = ui.Theme.acBlue },
			}
			local ping = ply:Ping()
			stats[#stats + 1] = { label = "PING", value = tostring(ping) .. "ms", color = ping < 80 and ui.Theme.acGreen or ping < 150 and ui.Theme.acGold or ui.Theme.acRed }
			local gap = 6
			local cardW = math.floor((w - (#stats - 1) * gap) / #stats)
			for i, s in ipairs(stats) do
				local cx = (i - 1) * (cardW + gap)
				draw.RoundedBox(4, cx, 0, cardW, h, Color(255, 255, 255, 4))
				draw.SimpleText(s.label, "MUI.SBStatLbl", cx + cardW * 0.5, 8, ui.Theme.muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
				draw.SimpleText(s.value, "MUI.SBStatVal", cx + cardW * 0.5, 28, s.color, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			end
		end

		local xpRow = vgui.Create("DPanel", scrl)
		xpRow:Dock(TOP)
		xpRow:SetTall(30)
		xpRow:DockMargin(0, 6, 0, 0)
		xpRow.Paint = function(self, w, h)
			local pXP = getPlayerXP(ply)
			local pMaxXP = getPlayerMaxXP(ply)
			local xpProg = pMaxXP > 0 and pXP / pMaxXP or 0
			draw.SimpleText("XP", "MUI.SBStatLbl", 0, 2, ui.Theme.muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			draw.SimpleText(tostring(pXP) .. " / " .. tostring(pMaxXP), "MUI.SBSmall", w, 2, ui.Theme.sub, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
			drawBar(0, 18, w, 8, xpProg, ui.Theme.acCyan)
		end

		if ply.GetUTimeTotalTime then
			local timeRow = vgui.Create("DPanel", scrl)
			timeRow:Dock(TOP)
			timeRow:SetTall(20)
			timeRow:DockMargin(0, 6, 0, 0)
			timeRow.Paint = function(self, w, h)
				draw.SimpleText("Total: " .. formatDuration(ply:GetUTimeTotalTime()), "MUI.SBSmall", 0, h * 0.5, ui.Theme.sub, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
				draw.SimpleText("Session: " .. formatDuration(ply:GetUTimeSessionTime()), "MUI.SBSmall", w, h * 0.5, ui.Theme.sub, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
			end
		end

		addSectionHeader("Quick Commands", "Player-facing shortcuts")
		local quickFlow = vgui.Create("DIconLayout", scrl)
		quickFlow:Dock(TOP)
		quickFlow:SetSpaceX(6)
		quickFlow:SetSpaceY(6)
		for _, action in ipairs(quickCommandButtons) do
			local btn = quickFlow:Add("DButton")
			btn:SetSize(action.name == "SERVER INFO" and 116 or 96, 28)
			btn:SetText("")
			btn.Paint = function(self, w, h)
				local hv = self:IsHovered()
				draw.RoundedBox(4, 0, 0, w, h, hv and action.color or Color(255, 255, 255, 6))
				draw.SimpleText(action.name, "MUI.SBAction", w * 0.5, h * 0.5, hv and Color(255, 255, 255) or action.color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
			btn.DoClick = function()
				runChatCommand(action.chat(ply))
			end
		end
		resizeIconLayout(quickFlow, 2)

		if adminTier >= 2 then
			for _, section in ipairs(adminActionSections) do
				if adminTier >= section.minTier then
					addSectionHeader(section.title, section.minTier >= 4 and "Owner tier" or section.minTier >= 3 and "Superadmin tier" or "Targeted staff actions")
					local flow = vgui.Create("DIconLayout", scrl)
					flow:Dock(TOP)
					flow:SetSpaceX(6)
					flow:SetSpaceY(6)
					for _, action in ipairs(section.buttons) do
						local btn = flow:Add("DButton")
						btn:SetSize(90, 28)
						btn:SetText("")
						btn.Paint = function(self, w, h)
							local hv = self:IsHovered()
							draw.RoundedBox(4, 0, 0, w, h, hv and action.color or Color(255, 255, 255, 6))
							draw.SimpleText(action.name, "MUI.SBAction", w * 0.5, h * 0.5, hv and Color(255, 255, 255) or action.color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
						end
						btn.DoClick = function()
							if action.prompt then
								action.prompt(ply)
								return
							end

							local function doRun()
								if action.selfTarget then
									runUlxCommand(action.cmd, nil, unpack(action.args or {}))
								else
									runUlxCommand(action.cmd, targetID, unpack(action.args or {}))
								end
							end
							if action.confirm then
								confirmAction(action.name, "Run " .. action.name .. " on " .. ply:Nick() .. "?", doRun)
							else
								doRun()
							end
						end
					end
					resizeIconLayout(flow, 2)
				end
			end
		end

		for _, ref in ipairs(commandReferenceSections) do
			if adminTier >= ref.minTier then
				addSectionHeader(ref.title)
				local box = vgui.Create("DPanel", scrl)
				box:Dock(TOP)
				box:DockMargin(0, 0, 0, 0)
				box:SetTall(86)
				box.Paint = function(self, w, h)
					draw.RoundedBox(4, 0, 0, w, h, Color(255, 255, 255, 3))
				end
				local lines = ref.lines(ply)
				local lbl = vgui.Create("DLabel", box)
				lbl:Dock(FILL)
				lbl:DockMargin(10, 8, 10, 8)
				lbl:SetFont("MUI.SBSmall")
				lbl:SetTextColor(ui.Theme.sub)
				lbl:SetWrap(true)
				lbl:SetAutoStretchVertical(true)
				lbl:SetText(table.concat(lines, "\n"))
				timer.Simple(0, function()
					if not IsValid(box) or not IsValid(lbl) then return end
					box:SetTall(math.max(lbl:GetTall() + 16, 54))
				end)
			end
		end

		addSectionHeader("External Links & Copy")
		local utilFlow = vgui.Create("DIconLayout", scrl)
		utilFlow:Dock(TOP)
		utilFlow:SetSpaceX(6)
		utilFlow:SetSpaceY(6)
		local utilBtns = {
			{ name = "STEAM PROFILE", w = 148, color = ui.Theme.acBlue, action = function() gui.OpenURL("https://steamcommunity.com/profiles/" .. tostring(pSID64)) end },
			{ name = "COPY NAME", w = 96, color = ui.Theme.acCyan, action = function() SetClipboardText(ply:Nick()) end },
			{ name = "COPY STEAMID", w = 116, color = ui.Theme.acGold, action = function() SetClipboardText(pSID) end },
			{ name = "COPY STEAM64", w = 116, color = ui.Theme.acPurple, action = function() SetClipboardText(tostring(pSID64)) end },
		}
		for _, ub in ipairs(utilBtns) do
			local btn = utilFlow:Add("DButton")
			btn:SetSize(ub.w, 30)
			btn:SetText("")
			btn.Paint = function(self, w, h)
				local hv = self:IsHovered()
				draw.RoundedBox(4, 0, 0, w, h, hv and ub.color or Color(255, 255, 255, 6))
				draw.SimpleText(ub.name, "MUI.SBAction", w * 0.5, h * 0.5, hv and Color(255, 255, 255) or ub.color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
			btn.DoClick = ub.action
		end
		resizeIconLayout(utilFlow, 2)
	end

	-- ── SHOW DETAIL ──
	function panel:ShowPlayerDetail(ply)
		if not IsValid(ply) then return end
		self._selectedPlayer = ply
		self._mode = "detail"
		self._listView:Hide()
		self._detailView:Show()
		self:BuildDetailContent(ply)
	end

	-- ── REFRESH LIST ──
	function panel:RefreshPlayers()
		if CurTime() - self._lastRefresh < 1 then return end
		if self._mode ~= "list" then return end
		self._lastRefresh = CurTime()

		local scrl = self._listScroll
		scrl:Clear()

		local me = LocalPlayer()
		local isAdm = IsValid(me) and (me:IsAdmin() or me:IsSuperAdmin())

		local teams = {}
		for _, ply in ipairs(player.GetAll()) do
			if not IsValid(ply) then continue end
			local t = ply:Team()
			if not teams[t] then
				teams[t] = { name = team.GetName(t) or "Unknown", color = team.GetColor(t) or Color(200, 210, 220), players = {} }
			end
			table.insert(teams[t].players, ply)
		end

		local sortedTeams = {}
		for id, data in pairs(teams) do
			table.insert(sortedTeams, { id = id, data = data })
		end
		table.sort(sortedTeams, function(a, b) return a.data.name < b.data.name end)

		for _, tInfo in ipairs(sortedTeams) do
			local tc = tInfo.data.color
			local tn = tInfo.data.name
			local tcount = #tInfo.data.players

			local teamHeader = vgui.Create("DPanel", scrl)
			teamHeader:Dock(TOP)
			teamHeader:SetTall(22)
			teamHeader:DockMargin(0, 4, 0, 2)
			teamHeader.Paint = function(self, w, h)
				surface.SetDrawColor(tc.r, tc.g, tc.b, 40)
				surface.DrawRect(0, h - 1, w, 1)
				draw.SimpleText(string.upper(tn) .. " (" .. tcount .. ")", "MUI.SBHeader", 8, h * 0.5, tc, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			end

			table.sort(tInfo.data.players, function(a, b)
				if not IsValid(a) or not IsValid(b) then return false end
				return (a:Nick() or "") < (b:Nick() or "")
			end)

			for _, ply in ipairs(tInfo.data.players) do
				if not IsValid(ply) then continue end

				local row = vgui.Create("DButton", scrl)
				row:Dock(TOP)
				row:SetTall(40)
				row:DockMargin(0, 0, 0, 2)
				row:SetText("")
				row:SetCursor("hand")

				local av = vgui.Create("AvatarImage", row)
				av:SetSize(28, 28)
				av:SetPos(6, 6)
				av:SetPlayer(ply, 64)
				av:SetMouseInputEnabled(false)

				local pName  = ply:Nick()
				local pJob   = (ply.getDarkRPVar and ply:getDarkRPVar("job")) or team.GetName(ply:Team()) or "?"
				local pLevel = getPlayerLevel(ply)
				local pPing  = ply:Ping()
				local tCol   = team.GetColor(ply:Team()) or Color(200, 210, 220)
				local pSID   = ply:SteamID()
				local pSID64 = ply:SteamID64()

				row.Paint = function(self, w, h)
					local hv = self:IsHovered()
					draw.RoundedBox(4, 0, 0, w, h, hv and Color(255, 255, 255, 10) or Color(255, 255, 255, 4))
					draw.SimpleText(pName, "MUI.SBName", 42, h * 0.5, tCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
					draw.SimpleText(pJob, "MUI.SBInfo", math.floor(w * 0.44), h * 0.5, ui.Theme.sub, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
					draw.SimpleText(tostring(pLevel), "MUI.SBSmall", math.floor(w * 0.70), h * 0.5, ui.Theme.acCyan, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
					local pingCol = pPing < 80 and ui.Theme.acGreen or pPing < 150 and ui.Theme.acGold or ui.Theme.acRed
					draw.SimpleText(tostring(pPing) .. " ms", "MUI.SBSmall", w - 12, h * 0.5, pingCol, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
				end

				row.DoClick = function()
					if IsValid(ply) then panel:ShowPlayerDetail(ply) end
				end

				row.DoRightClick = function()
					if not IsValid(ply) then return end
					local dm = DermaMenu()
					dm:AddOption("View Player", function() panel:ShowPlayerDetail(ply) end)
					dm:AddOption("Copy Name", function() SetClipboardText(pName) end)
					dm:AddOption("Copy SteamID", function() SetClipboardText(pSID) end)
					dm:AddOption("Steam Profile", function() gui.OpenURL("https://steamcommunity.com/profiles/" .. tostring(pSID64)) end)
					if isAdm then
						dm:AddSpacer()
						local targetID = "#" .. tostring(ply:UserID())
						dm:AddOption("Goto", function() RunConsoleCommand("ulx", "goto", targetID) end)
						dm:AddOption("Bring", function() RunConsoleCommand("ulx", "bring", targetID) end)
						dm:AddOption("Kick", function() RunConsoleCommand("ulx", "kick", targetID) end)
						dm:AddOption("Freeze", function() RunConsoleCommand("ulx", "freeze", targetID) end)
						dm:AddOption("Slay", function() RunConsoleCommand("ulx", "slay", targetID) end)
						local banSub, banParent = dm:AddSubMenu("Ban...")
						banSub:AddOption("1 Hour", function() RunConsoleCommand("ulx", "ban", targetID, "60") end)
						banSub:AddOption("1 Day", function() RunConsoleCommand("ulx", "ban", targetID, "1440") end)
						banSub:AddOption("1 Week", function() RunConsoleCommand("ulx", "ban", targetID, "10080") end)
						banSub:AddOption("Permanent", function() RunConsoleCommand("ulx", "ban", targetID, "0") end)
					end
					dm:Open()
				end
			end
		end
	end

	-- ── THINK ──
	function panel:Think()
		if input.IsMouseDown(MOUSE_4) then
			if not self._mouse4Held then
				self._mouse4Held = true
				if self._mode == "detail" then
					self._mode = "list"
					self._listView:Show()
					self._detailView:Hide()
				end
			end
		else
			self._mouse4Held = false
		end

		if self._mode == "detail" and not IsValid(self._selectedPlayer) then
			self._mode = "list"
			self._listView:Show()
			self._detailView:Hide()
		end

		if self._mode == "list" then
			self:RefreshPlayers()
		end
	end

	panel:Hide()
	ui.ScorePanel = panel
	return panel
end

-- ==========================================================================
-- CUSTOM F4 MENU (Sidebar + Tabs)
-- ==========================================================================

local f4NavItems = {
	{ key = "jobs",      label = "JOBS",      icon = "J" },
	{ key = "entities",  label = "ENTITIES",  icon = "E" },
	{ key = "shipments", label = "SHIPMENTS", icon = "S" },
	{ key = "weapons",   label = "WEAPONS",   icon = "W" },
	{ key = "ammo",      label = "AMMO",      icon = "A" },
	{ key = "vehicles",  label = "VEHICLES",  icon = "V" },
}

local function createF4Menu()
	if IsValid(ui.F4Panel) then ui.F4Panel:Remove() end

	local sw, sh = ScrW(), ScrH()
	local pw = math.Clamp(math.floor(sw * 0.82), 900, 1400)
	local ph = math.Clamp(math.floor(sh * 0.82), 600, 950)

	local frame = vgui.Create("DFrame")
	frame:SetSize(pw, ph)
	frame:Center()
	frame:MakePopup()
	frame:SetTitle("")
	frame:ShowCloseButton(false)
	frame:SetDraggable(false)
	frame.Paint = function(self, w, h)
		drawGlassPanel(0, 0, w, h, 8, ui.Theme.acBlue)
	end

	function frame:Close()
		self:Hide()
	end

	frame._activeTab = "jobs"
	frame._contentPanels = {}

	-- ── SIDEBAR ──
	local sideW = 180
	local sidebar = vgui.Create("DPanel", frame)
	sidebar:Dock(LEFT)
	sidebar:SetWide(sideW)
	sidebar.Paint = function(self, w, h)
		draw.RoundedBoxEx(8, 0, 0, w, h, Color(0, 0, 0, 40), true, false, true, false)
		surface.SetDrawColor(255, 255, 255, 6)
		surface.DrawRect(w - 1, 0, 1, h)
	end

	-- Sidebar header
	local sideHead = vgui.Create("DPanel", sidebar)
	sideHead:Dock(TOP)
	sideHead:SetTall(85)
	sideHead.Paint = function(self, w, h)
		draw.SimpleText("DARKRP", "MUI.F4Title", w * 0.5, 12, ui.Theme.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		local ply = LocalPlayer()
		if IsValid(ply) then
			draw.SimpleText("Lv " .. getPlayerLevel(ply), "MUI.SBSub", w * 0.5, 40, ui.Theme.acCyan, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			draw.SimpleText(formatMoney(tonumber(ply.getDarkRPVar and ply:getDarkRPVar("money")) or 0), "MUI.SBSub", w * 0.5, 56, ui.Theme.acGold, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		end
		surface.SetDrawColor(255, 255, 255, 8)
		surface.DrawRect(16, h - 1, w - 32, 1)
	end

	-- CONTENT AREA
	local contentArea = vgui.Create("DPanel", frame)
	contentArea:Dock(FILL)
	contentArea:DockMargin(0, 24, 0, 0)
	contentArea.Paint = function() end
	frame._contentArea = contentArea

	-- Nav buttons
	for _, navItem in ipairs(f4NavItems) do
		local btn = vgui.Create("DButton", sidebar)
		btn:Dock(TOP)
		btn:SetTall(36)
		btn:DockMargin(10, 2, 10, 2)
		btn:SetText("")
		btn._navKey = navItem.key

		btn.Paint = function(self, w, h)
			local active = frame._activeTab == self._navKey
			local hv = self:IsHovered()
			if active then
				draw.RoundedBox(4, 0, 0, w, h, ui.Theme.acBlue)
			elseif hv then
				draw.RoundedBox(4, 0, 0, w, h, Color(255, 255, 255, 10))
			end
			local tc = active and Color(255, 255, 255) or (hv and ui.Theme.text or ui.Theme.sub)
			draw.SimpleText(navItem.icon, "MUI.F4Nav", 16, h * 0.5, tc, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.SimpleText(navItem.label, "MUI.F4Nav", 30, h * 0.5, tc, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end

		btn.DoClick = function()
			frame._activeTab = navItem.key
			frame:SwitchTab(navItem.key)
		end
	end

	-- Close button at sidebar bottom
	local closeBtn = vgui.Create("DButton", sidebar)
	closeBtn:Dock(BOTTOM)
	closeBtn:SetTall(36)
	closeBtn:DockMargin(10, 0, 10, 16)
	closeBtn:SetText("")
	closeBtn.Paint = function(self, w, h)
		local hv = self:IsHovered()
		draw.RoundedBox(4, 0, 0, w, h, hv and ui.Theme.acRed or Color(255, 255, 255, 6))
		draw.SimpleText("CLOSE", "MUI.F4Nav", w * 0.5, h * 0.5, hv and Color(255, 255, 255) or ui.Theme.sub, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	closeBtn.DoClick = function() frame:Hide() end

	-- ── TAB SWITCHING ──
	function frame:SwitchTab(key)
		for _, p in pairs(self._contentPanels) do
			if IsValid(p) then p:Remove() end
		end
		self._contentPanels = {}

		if key == "jobs" then
			self._contentPanels[key] = self:BuildJobsTab()
		else
			self._contentPanels[key] = self:BuildShopTab(key)
		end
	end

	-- ── JOBS TAB ──
	function frame:BuildJobsTab()
		local parent = self._contentArea
		local container = vgui.Create("DPanel", parent)
		container:Dock(FILL)
		container:DockMargin(12, 0, 12, 12)
		container.Paint = function() end

		-- Left: job list
		local leftPanel = vgui.Create("DPanel", container)
		leftPanel:Dock(LEFT)
		leftPanel:SetWide(300)
		leftPanel:DockMargin(0, 0, 8, 0)
		leftPanel.Paint = function(self, w, h)
			draw.RoundedBox(6, 0, 0, w, h, Color(255, 255, 255, 3))
		end

		local jobScroll = vgui.Create("DScrollPanel", leftPanel)
		jobScroll:Dock(FILL)
		jobScroll:DockMargin(6, 6, 6, 6)
		styleScrollPanel(jobScroll)

		-- Right: detail
		local rightPanel = vgui.Create("DScrollPanel", container)
		rightPanel:Dock(FILL)
		rightPanel:DockMargin(0, 0, 0, 0)
		styleScrollPanel(rightPanel)
		container._rightScroll = rightPanel
		container._selectedJob = nil
		local firstJob = nil

		-- Populate job list
		local jobs = RPExtraTeams or {}
		local categories = {}
		for k, v in pairs(jobs) do
			local cat = v.category or "Other"
			if not categories[cat] then categories[cat] = {} end
			table.insert(categories[cat], { idx = k, data = v })
		end

		for catName, catJobs in SortedPairs(categories) do
			local catHeader = vgui.Create("DPanel", jobScroll)
			catHeader:Dock(TOP)
			catHeader:SetTall(24)
			catHeader:DockMargin(0, 4, 0, 2)
			catHeader.Paint = function(self, w, h)
				draw.SimpleText(string.upper(catName), "MUI.SBHeader", 6, h * 0.5, ui.Theme.sub, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
				surface.SetDrawColor(255, 255, 255, 8)
				surface.DrawRect(0, h - 1, w, 1)
			end

			table.sort(catJobs, function(a, b) return (a.data.name or "") < (b.data.name or "") end)

			for _, jobInfo in ipairs(catJobs) do
				local job = jobInfo.data
				local jIdx = jobInfo.idx
				if not firstJob then firstJob = { idx = jIdx, data = job } end
				local jColor = job.color or Color(200, 210, 220)
				local jName = job.name or "Unknown"
				local jSalary = formatMoney(job.salary or 0)
				local jMax = job.max or 0
				local jTeam = job.team or 0
				local jModel = pickValidModel(job.model, LocalPlayer():GetModel(), "models/player/kleiner.mdl")

				local jobBtn = vgui.Create("DButton", jobScroll)
				jobBtn:Dock(TOP)
				jobBtn:SetTall(46)
				jobBtn:DockMargin(0, 0, 0, 2)
				jobBtn:SetText("")

				if jModel then
					local icon = vgui.Create("SpawnIcon", jobBtn)
					icon:SetPos(8, 5)
					icon:SetSize(36, 36)
					icon:SetModel(jModel)
					icon:SetTooltip(false)
					icon:SetMouseInputEnabled(false)
				else
					local placeholder = createCompactPlaceholder(jobBtn, getInitials(jName), jColor)
					placeholder:SetPos(8, 5)
				end

				jobBtn.Paint = function(self, w, h)
					local hv = self:IsHovered()
					local sel = container._selectedJob == jIdx
					local bg = sel and ColorAlpha(jColor, 20) or (hv and Color(255, 255, 255, 8) or Color(255, 255, 255, 3))
					draw.RoundedBox(4, 0, 0, w, h, bg)
					draw.RoundedBox(3, 0, 8, 3, h - 16, ColorAlpha(jColor, sel and 200 or 60))
					draw.SimpleText(jName, "MUI.F4Item", 54, 6, sel and jColor or ui.Theme.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
					local jCount = team.NumPlayers(jTeam)
					local countTxt = jMax > 0 and (jCount .. "/" .. jMax) or tostring(jCount)
					draw.SimpleText(jSalary, "MUI.F4Meta", 54, 24, ui.Theme.acGold, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
					draw.SimpleText(countTxt, "MUI.F4Meta", w - 6, h * 0.5, ui.Theme.muted, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
				end

				jobBtn.DoClick = function()
					container._selectedJob = jIdx
					self:ShowJobDetail(container, job, jIdx)
				end
			end
		end

		timer.Simple(0, function()
			if not IsValid(container) then return end
			local current = RPExtraTeams and RPExtraTeams[LocalPlayer():Team()]
			if current then
				container._selectedJob = LocalPlayer():Team()
				self:ShowJobDetail(container, current, LocalPlayer():Team())
			elseif firstJob then
				container._selectedJob = firstJob.idx
				self:ShowJobDetail(container, firstJob.data, firstJob.idx)
			end
		end)

		return container
	end

	function frame:ShowJobDetail(container, job, jobIdx)
		local scrl = container._rightScroll
		scrl:Clear()

		local ply = LocalPlayer()
		local wrapper = vgui.Create("DPanel", scrl)
		wrapper:Dock(TOP)
		wrapper:DockMargin(8, 0, 8, 0)
		wrapper:SetTall(64)
		wrapper.Paint = function(self, w, h)
			draw.RoundedBox(6, 0, 0, w, h, Color(255, 255, 255, 3))
		end

		local models = {}
		local seenModels = {}
		if istable(job.model) then
			for _, modelPath in ipairs(job.model) do
				local resolvedModel = pickValidModel(modelPath)
				local modelKey = resolvedModel and string.lower(resolvedModel)
				if resolvedModel and not seenModels[modelKey] then
					seenModels[modelKey] = true
					models[#models + 1] = resolvedModel
				end
			end
		elseif pickValidModel(job.model) then
			models[1] = pickValidModel(job.model)
		end
		if #models == 0 then models[1] = pickValidModel(LocalPlayer():GetModel(), "models/player/kleiner.mdl") end

		local previewShell = vgui.Create("DPanel", wrapper)
		previewShell:Dock(TOP)
		previewShell:SetTall(300)
		previewShell:DockMargin(12, 12, 12, 0)
		previewShell.Paint = function(self, w, h)
			draw.RoundedBox(4, 0, 0, w, h, Color(255, 255, 255, 4))
		end
		previewShell:DockPadding(12, 12, 12, 12)

		local modelIndex = 1
		local heroCard, _, setHeroModel, setHeroFooter = createModelPreviewCard(previewShell, "MODEL 1 / " .. #models)
		heroCard:Dock(FILL)

		local modelStrip = nil
		if #models > 1 then
			modelStrip = vgui.Create("DIconLayout", previewShell)
			modelStrip:Dock(BOTTOM)
			modelStrip:SetTall(76)
			modelStrip:DockMargin(0, 10, 0, 0)
			modelStrip:SetSpaceX(8)
			modelStrip:SetSpaceY(0)
		end

		local thumbButtons = {}
		local function refreshThumbState()
			for idx, btn in ipairs(thumbButtons) do
				if IsValid(btn) then
					btn._selected = idx == modelIndex
				end
			end
		end

		local function applyModelIndex(idx)
			modelIndex = ((idx - 1) % #models) + 1
			setHeroModel(models[modelIndex])
			setHeroFooter("MODEL " .. modelIndex .. " / " .. #models)
			refreshThumbState()
		end

		if modelStrip then
			for idx, modelPath in ipairs(models) do
				local thumb = modelStrip:Add("DButton")
				thumb:SetSize(68, 68)
				thumb:SetText("")
				thumb.Paint = function(self, w, h)
					local selected = self._selected
					local hovered = self:IsHovered()
					local bg = selected and ColorAlpha(ui.Theme.acBlue, 24) or (hovered and Color(255, 255, 255, 8) or Color(255, 255, 255, 4))
					draw.RoundedBox(6, 0, 0, w, h, bg)
					surface.SetDrawColor(selected and ui.Theme.acBlue or Color(255, 255, 255, hovered and 22 or 10))
					surface.DrawOutlinedRect(0, 0, w, h, 1)
				end

				local icon = vgui.Create("SpawnIcon", thumb)
				icon:SetPos(6, 6)
				icon:SetSize(56, 56)
				icon:SetModel(modelPath)
				icon:SetTooltip(false)
				icon:SetMouseInputEnabled(false)

				thumb.DoClick = function()
					applyModelIndex(idx)
				end

				thumbButtons[idx] = thumb
			end
		end

		applyModelIndex(1)

		-- Name
		local nameLbl = vgui.Create("DLabel", wrapper)
		nameLbl:Dock(TOP)
		nameLbl:DockMargin(16, 8, 16, 0)
		nameLbl:SetTall(28)
		nameLbl:SetFont("MUI.F4Big")
		nameLbl:SetTextColor(job.color or ui.Theme.text)
		nameLbl:SetText(job.name or "Unknown")

		-- Description
		local descLbl = vgui.Create("DLabel", wrapper)
		descLbl:Dock(TOP)
		descLbl:DockMargin(16, 4, 16, 0)
		descLbl:SetFont("MUI.F4Desc")
		descLbl:SetTextColor(ui.Theme.sub)
		descLbl:SetText(job.description or "No description available.")
		descLbl:SetWrap(true)
		descLbl:SetAutoStretchVertical(true)

		-- Info bar
		local infoBar = vgui.Create("DPanel", wrapper)
		infoBar:Dock(TOP)
		infoBar:SetTall(26)
		infoBar:DockMargin(16, 8, 16, 0)
		infoBar.Paint = function(self, w, h)
			draw.SimpleText("Salary: " .. formatMoney(job.salary or 0), "MUI.F4Meta", 0, h * 0.5, ui.Theme.acGold, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			local maxText = (job.max and job.max > 0) and ("Max: " .. job.max .. " players") or "Unlimited slots"
			draw.SimpleText(maxText, "MUI.F4Meta", w, h * 0.5, ui.Theme.sub, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
		end

		-- Weapons
		if job.weapons and #job.weapons > 0 then
			local wepHdr = vgui.Create("DLabel", wrapper)
			wepHdr:Dock(TOP)
			wepHdr:DockMargin(16, 8, 16, 0)
			wepHdr:SetTall(16)
			wepHdr:SetFont("MUI.SBHeader")
			wepHdr:SetTextColor(ui.Theme.muted)
			wepHdr:SetText("WEAPONS")

			local weaponFlow = vgui.Create("DIconLayout", wrapper)
			weaponFlow:Dock(TOP)
			weaponFlow:DockMargin(16, 6, 16, 0)
			weaponFlow:SetSpaceX(6)
			weaponFlow:SetSpaceY(6)
			for _, className in ipairs(job.weapons) do
				local displayName, modelPath = getWeaponDisplayData(className)
				local tile = weaponFlow:Add("DPanel")
				tile:SetSize(84, 84)
				tile.Paint = function(self, w, h)
					draw.RoundedBox(4, 0, 0, w, h, Color(255, 255, 255, 4))
					draw.SimpleText(displayName, "MUI.SBSmall", w * 0.5, h - 18, ui.Theme.sub, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				end
				if modelPath then
					local icon = vgui.Create("SpawnIcon", tile)
					icon:SetPos(14, 8)
					icon:SetSize(56, 56)
					icon:SetModel(modelPath)
					icon:SetMouseInputEnabled(false)
				else
					createCompactPlaceholder(tile, getInitials(displayName), ui.Theme.acBlue)
				end
			end
			resizeIconLayout(weaponFlow, 2)
		end

		-- Can become check
		local canBecome = true
		local unavailableReason = nil
		if IsValid(ply) then
			if ply:Team() == (job.team or -1) then canBecome = false unavailableReason = "You are already on this job." end
			if job.customCheck and not job.customCheck(ply) then canBecome = false unavailableReason = unavailableReason or "Custom requirements are not met." end
			if job.max and job.max > 0 and team.NumPlayers(job.team or 0) >= job.max then canBecome = false unavailableReason = unavailableReason or "This job is full right now." end
			if job.admin then
				if job.admin >= 2 and not ply:IsSuperAdmin() then canBecome = false unavailableReason = unavailableReason or "Superadmin rank required." end
				if job.admin >= 1 and not ply:IsAdmin() and not ply:IsSuperAdmin() then canBecome = false unavailableReason = unavailableReason or "Admin rank required." end
			end
		end

		if unavailableReason then
			local statusLbl = vgui.Create("DLabel", wrapper)
			statusLbl:Dock(TOP)
			statusLbl:DockMargin(16, 10, 16, 0)
			statusLbl:SetTall(18)
			statusLbl:SetFont("MUI.F4Meta")
			statusLbl:SetTextColor(ui.Theme.acOrange)
			statusLbl:SetText(unavailableReason)
		end

		-- Become button
		local becomeBtn = vgui.Create("DButton", wrapper)
		becomeBtn:Dock(TOP)
		becomeBtn:SetTall(42)
		becomeBtn:DockMargin(16, 12, 16, 16)
		becomeBtn:SetText("")
		becomeBtn.Paint = function(self, w, h)
			local hv = self:IsHovered()
			if canBecome then
				draw.RoundedBox(6, 0, 0, w, h, hv and ui.Theme.acCyan or ui.Theme.acBlue)
				if hv then
					surface.SetMaterial(gradientUp)
					surface.SetDrawColor(255, 255, 255, 20)
					surface.DrawTexturedRect(0, 0, w, math.floor(h * 0.5))
				end
				draw.SimpleText("BECOME " .. string.upper(job.name or ""), "MUI.F4Section", w * 0.5, h * 0.5, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			else
				draw.RoundedBox(6, 0, 0, w, h, Color(255, 255, 255, 4))
				draw.SimpleText("UNAVAILABLE", "MUI.F4Section", w * 0.5, h * 0.5, ui.Theme.muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
		end
		becomeBtn.DoClick = function()
			if canBecome and job.command then
				RunConsoleCommand("darkrp", job.command)
				frame:Hide()
			end
		end

		-- Resize wrapper to fit content
		updateDockedWrapperHeight(wrapper, 16)
	end

	-- ── SHOP TAB (Entities/Shipments/Weapons/Ammo/Vehicles) ──
	function frame:BuildShopTab(tabKey)
		local parent = self._contentArea
		local container = vgui.Create("DPanel", parent)
		container:Dock(FILL)
		container:DockMargin(12, 0, 12, 12)
		container.Paint = function() end

		-- Left: item list
		local leftPanel = vgui.Create("DPanel", container)
		leftPanel:Dock(LEFT)
		leftPanel:SetWide(300)
		leftPanel:DockMargin(0, 0, 8, 0)
		leftPanel.Paint = function(self, w, h)
			draw.RoundedBox(6, 0, 0, w, h, Color(255, 255, 255, 3))
		end

		-- Title
		local titleLabels = { entities = "ENTITIES", shipments = "SHIPMENTS", weapons = "WEAPONS", ammo = "AMMO", vehicles = "VEHICLES" }
		local titleLbl = vgui.Create("DPanel", leftPanel)
		titleLbl:Dock(TOP)
		titleLbl:SetTall(30)
		titleLbl:DockMargin(10, 8, 10, 4)
		titleLbl.Paint = function(self, w, h)
			draw.SimpleText(titleLabels[tabKey] or "SHOP", "MUI.F4Section", 0, h * 0.5, ui.Theme.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end

		local itemScroll = vgui.Create("DScrollPanel", leftPanel)
		itemScroll:Dock(FILL)
		itemScroll:DockMargin(6, 0, 6, 6)
		styleScrollPanel(itemScroll)

		-- Right: detail
		local rightPanel = vgui.Create("DScrollPanel", container)
		rightPanel:Dock(FILL)
		rightPanel:DockMargin(0, 0, 0, 0)
		styleScrollPanel(rightPanel)
		container._rightScroll = rightPanel
		container._selectedItem = nil
		local firstItem = nil

		-- Gather items
		local items = {}
		local ply = LocalPlayer()

		if tabKey == "entities" then
			for k, v in pairs(DarkRPEntities or {}) do
				local canBuy = true
				if v.allowed and #v.allowed > 0 then
					canBuy = false
					if IsValid(ply) then
						for _, t in ipairs(v.allowed) do
							if t == ply:Team() then canBuy = true break end
						end
					end
				end
				if v.customCheck and IsValid(ply) and not v.customCheck(ply) then canBuy = false end
				table.insert(items, { name = v.name, model = v.model, price = v.price, cmd = v.cmd, max = v.max, canBuy = canBuy, category = v.category, entityClass = v.ent })
			end

		elseif tabKey == "shipments" then
			for k, v in pairs(CustomShipments or {}) do
				if not v.separate then
					local canBuy = true
					if v.allowed and #v.allowed > 0 then
						canBuy = false
						if IsValid(ply) then
							for _, t in ipairs(v.allowed) do
								if t == ply:Team() then canBuy = true break end
							end
						end
					end
					if v.customCheck and IsValid(ply) and not v.customCheck(ply) then canBuy = false end
					table.insert(items, { name = v.name, model = v.model, shipModel = "models/items/item_item_crate.mdl", price = v.price, amount = v.amount, canBuy = canBuy, cmd = "buyshipment", arg = v.name, category = v.category, entityClass = v.entity })
				end
			end

		elseif tabKey == "weapons" then
			for k, v in pairs(CustomShipments or {}) do
				if v.separate then
					local canBuy = true
					if v.allowed and #v.allowed > 0 then
						canBuy = false
						if IsValid(ply) then
							for _, t in ipairs(v.allowed) do
								if t == ply:Team() then canBuy = true break end
							end
						end
					end
					if v.customCheck and IsValid(ply) and not v.customCheck(ply) then canBuy = false end
					table.insert(items, { name = v.name, model = v.model, price = v.pricesep or v.price, canBuy = canBuy, cmd = "buy", arg = v.name, category = v.category, entityClass = v.entity })
				end
			end

		elseif tabKey == "ammo" then
			local gm = gmod.GetGamemode()
			local ammoTypes = gm and gm.AmmoTypes or {}
			for k, v in pairs(ammoTypes) do
				table.insert(items, { name = v.name or "Ammo", price = v.price, cmd = "buyammo", arg = tostring(v.id or k), canBuy = true, entityClass = tostring(v.id or k) })
			end

		elseif tabKey == "vehicles" then
			for k, v in pairs(CustomVehicles or {}) do
				local canBuy = true
				if v.allowed and #v.allowed > 0 then
					canBuy = false
					if IsValid(ply) then
						for _, t in ipairs(v.allowed) do
							if t == ply:Team() then canBuy = true break end
						end
					end
				end
				if v.customCheck and IsValid(ply) and not v.customCheck(ply) then canBuy = false end
				table.insert(items, { name = v.name, model = v.model, price = v.price, canBuy = canBuy, cmd = "buyvehicle", arg = v.name, category = v.category })
			end
		end

		table.sort(items, function(a, b) return (a.name or "") < (b.name or "") end)

		for _, item in ipairs(items) do
			item.previewModel, item.secondaryPreviewModel = getShopItemPreview(item, tabKey)
		end

		if #items == 0 then
			local emptyLbl = vgui.Create("DLabel", itemScroll)
			emptyLbl:Dock(TOP)
			emptyLbl:SetTall(40)
			emptyLbl:SetFont("MUI.F4Body")
			emptyLbl:SetTextColor(ui.Theme.muted)
			emptyLbl:SetText("  No items available.")
		end

		for i, item in ipairs(items) do
			if not firstItem then firstItem = { index = i, data = item } end
			local btn = vgui.Create("DButton", itemScroll)
			btn:Dock(TOP)
			btn:SetTall(48)
			btn:DockMargin(0, 0, 0, 2)
			btn:SetText("")

			local icon = nil
			if item.previewModel then
				icon = vgui.Create("SpawnIcon", btn)
				icon:SetPos(6, 6)
				icon:SetSize(36, 36)
				icon:SetModel(item.previewModel)
				icon:SetMouseInputEnabled(false)
			else
				icon = createCompactPlaceholder(btn, getInitials(item.name), ui.Theme.acBlue)
			end

			btn.Paint = function(self, w, h)
				local hv = self:IsHovered()
				local sel = container._selectedItem == i
				local bg = sel and Color(255, 255, 255, 12) or (hv and Color(255, 255, 255, 8) or Color(255, 255, 255, 3))
				draw.RoundedBox(4, 0, 0, w, h, bg)
				if not item.canBuy then
					surface.SetDrawColor(0, 0, 0, 80)
					surface.DrawRect(1, 1, w - 2, h - 2)
				end
				local textX = 50
				draw.SimpleText(item.name or "?", "MUI.F4Item", textX, 5, item.canBuy and ui.Theme.text or ui.Theme.muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				draw.SimpleText(formatMoney(item.price or 0), "MUI.F4Meta", textX, 26, ui.Theme.acGold, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				if item.amount then
					draw.SimpleText("x" .. item.amount, "MUI.F4Meta", w - 8, h * 0.5, ui.Theme.sub, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
				end
			end

			btn.DoClick = function()
				container._selectedItem = i
				self:ShowItemDetail(container, item, tabKey)
			end
		end

		timer.Simple(0, function()
			if not IsValid(container) or not firstItem then return end
			container._selectedItem = firstItem.index
			self:ShowItemDetail(container, firstItem.data, tabKey)
		end)

		return container
	end

	function frame:ShowItemDetail(container, item, tabKey)
		local scrl = container._rightScroll
		scrl:Clear()

		local wrapper = vgui.Create("DPanel", scrl)
		wrapper:Dock(TOP)
		wrapper:DockMargin(8, 0, 8, 0)
		wrapper:SetTall(64)
		wrapper.Paint = function(self, w, h)
			draw.RoundedBox(6, 0, 0, w, h, Color(255, 255, 255, 3))
		end

		local previewShell = vgui.Create("DPanel", wrapper)
		previewShell:Dock(TOP)
		previewShell:SetTall(280)
		previewShell:DockMargin(12, 12, 12, 0)
		previewShell.Paint = function(self, w, h)
			draw.RoundedBox(4, 0, 0, w, h, Color(255, 255, 255, 4))
		end
		previewShell:DockPadding(12, 12, 12, 12)

		if tabKey == "shipments" then
			local rightPreview = nil
			if item.secondaryPreviewModel then
				rightPreview = vgui.Create("DPanel", previewShell)
				rightPreview:Dock(RIGHT)
				rightPreview:SetWide(192)
				rightPreview:DockMargin(12, 0, 0, 0)
				rightPreview.Paint = function() end
			end

			local crateCard, _, setCrateModel = createModelPreviewCard(previewShell, "SHIPMENT")
			crateCard:Dock(FILL)
			setCrateModel(pickValidModel(item.previewModel, item.shipModel, "models/items/item_item_crate.mdl"))

			if item.secondaryPreviewModel then
				local weaponCard, _, setWeaponModel = createModelPreviewCard(rightPreview, "CONTENTS")
				weaponCard:Dock(FILL)
				setWeaponModel(item.secondaryPreviewModel)
			end

			local qtyBadge = vgui.Create("DPanel", previewShell)
			qtyBadge:SetSize(70, 24)
			qtyBadge:SetPos(12, 12)
			qtyBadge.Paint = function(self, w, h)
				draw.RoundedBox(4, 0, 0, w, h, ColorAlpha(ui.Theme.acGold, 30))
				draw.SimpleText("x" .. tostring(item.amount or 1), "MUI.SBAction", w * 0.5, h * 0.5, ui.Theme.acGold, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
		elseif item.previewModel then
			local itemCard, _, setItemModel = createModelPreviewCard(previewShell, string.upper(tabKey or "ITEM") .. " PREVIEW")
			itemCard:Dock(FILL)
			setItemModel(item.previewModel)
		else
			createPreviewPlaceholder(previewShell, string.upper(tabKey or "ITEM") .. " PREVIEW", "No usable model was provided for this item.", ui.Theme.acOrange)
		end

		-- Name
		local nameLbl = vgui.Create("DLabel", wrapper)
		nameLbl:Dock(TOP)
		nameLbl:DockMargin(16, 10, 16, 0)
		nameLbl:SetTall(26)
		nameLbl:SetFont("MUI.F4Big")
		nameLbl:SetTextColor(ui.Theme.text)
		nameLbl:SetText(item.name or "Unknown")

		-- Price
		local priceLbl = vgui.Create("DLabel", wrapper)
		priceLbl:Dock(TOP)
		priceLbl:DockMargin(16, 4, 16, 0)
		priceLbl:SetTall(20)
		priceLbl:SetFont("MUI.F4Price")
		priceLbl:SetTextColor(ui.Theme.acGold)
		priceLbl:SetText("Price: " .. formatMoney(item.price or 0))

		if item.amount then
			local amtLbl = vgui.Create("DLabel", wrapper)
			amtLbl:Dock(TOP)
			amtLbl:DockMargin(16, 2, 16, 0)
			amtLbl:SetTall(18)
			amtLbl:SetFont("MUI.F4Meta")
			amtLbl:SetTextColor(ui.Theme.sub)
			amtLbl:SetText("Quantity per shipment: " .. item.amount)
		end

		-- Buy button
		local buyBtn = vgui.Create("DButton", wrapper)
		buyBtn:Dock(TOP)
		buyBtn:SetTall(42)
		buyBtn:DockMargin(16, 16, 16, 16)
		buyBtn:SetText("")
		buyBtn.Paint = function(self, w, h)
			local hv = self:IsHovered()
			if item.canBuy then
				draw.RoundedBox(6, 0, 0, w, h, hv and ui.Theme.acCyan or ui.Theme.acBlue)
				if hv then
					surface.SetMaterial(gradientUp)
					surface.SetDrawColor(255, 255, 255, 20)
					surface.DrawTexturedRect(0, 0, w, math.floor(h * 0.5))
				end
				draw.SimpleText("PURCHASE", "MUI.F4Section", w * 0.5, h * 0.5, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			else
				draw.RoundedBox(6, 0, 0, w, h, Color(255, 255, 255, 4))
				draw.SimpleText("UNAVAILABLE", "MUI.F4Section", w * 0.5, h * 0.5, ui.Theme.muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
		end
		buyBtn.DoClick = function()
			if not item.canBuy then return end
			if tabKey == "entities" and item.cmd then
				RunConsoleCommand("darkrp", item.cmd)
			elseif item.cmd and item.arg then
				RunConsoleCommand("darkrp", item.cmd, item.arg)
			end
		end

		updateDockedWrapperHeight(wrapper, 16)
	end

	-- Start with jobs tab
	frame:SwitchTab("jobs")
	frame:Hide()
	ui.F4Panel = frame
	return frame
end

-- ==========================================================================
-- MODERN CHAT STYLING
-- ==========================================================================

local chatRoleColors = {
	superadmin = Color(228, 100, 100),
	admin      = Color(245, 202, 88),
	operator   = Color(108, 195, 126),
	moderator  = Color(168, 130, 255),
	vip        = Color(86, 228, 220),
	donator    = Color(86, 228, 220),
}

local function setupChatHook()
	hook.Remove("OnPlayerChat", "Tags.OnPlayerChat")

	hook.Add("OnPlayerChat", "MUI_ChatStyle", function(ply, text, teamOnly, dead)
		local tab = {}
		if dead then
			table.insert(tab, Color(220, 55, 55))
			table.insert(tab, "DEAD ")
		end
		if teamOnly then
			table.insert(tab, Color(55, 180, 70))
			table.insert(tab, "(TEAM) ")
		end
		if IsValid(ply) and ply.GetUserGroup and ply:GetUserGroup() ~= "user" then
			local group = ply:GetUserGroup()
			local tagCol = chatRoleColors[group] or ui.Theme.acBlue
			table.insert(tab, tagCol)
			table.insert(tab, string.upper(group))
			table.insert(tab, Color(255, 255, 255, 50))
			table.insert(tab, " \194\183 ")
		end
		if IsValid(ply) then
			local teamCol = team.GetColor(ply:Team()) or Color(150, 210, 255)
			table.insert(tab, teamCol)
			table.insert(tab, ply:Nick())
		else
			table.insert(tab, Color(200, 200, 200))
			table.insert(tab, "Console")
		end
		table.insert(tab, Color(235, 240, 245))
		table.insert(tab, ": " .. text)
		chat.AddText(unpack(tab))
		return true
	end)
end

-- ==========================================================================
-- /PLAYED NET RECEIVER + CONSOLE COMMAND
-- ==========================================================================

net.Receive("MUI_ShowPlayed", function()
	ui.State.playedShow = CurTime()
end)

concommand.Add("played", function()
	ui.State.playedShow = CurTime()
end)

-- ==========================================================================
-- HOOK REGISTRATIONS
-- ==========================================================================

hook.Add("HUDShouldDraw", "MUI_HideLegacy", function(name)
	if hiddenHudElements[name] then return false end
end)

hook.Add("Think", "MUI_InspectToggle", updateInspectMode)

hook.Add("HUDPaint", "MUI_DrawHUD", drawHUD)

-- Scoreboard hooks
hook.Add("ScoreboardShow", "MUI_Scoreboard", function()
	if not IsValid(ui.ScorePanel) then createScoreboard() end
	if IsValid(ui.ScorePanel) then
		ui.ScorePanel:Show()
		ui.ScorePanel:MakePopup()
		ui.ScorePanel:SetKeyboardInputEnabled(false)
		ui.ScorePanel._lastRefresh = 0
	end
	return true
end)

hook.Add("ScoreboardHide", "MUI_Scoreboard", function()
	if IsValid(ui.ScorePanel) then
		ui.ScorePanel:Hide()
	end
	return true
end)

-- F4 Menu override
local function showF4()
	if not IsValid(ui.F4Panel) then createF4Menu() end
	if IsValid(ui.F4Panel) then
		ui.F4Panel:Show()
		ui.F4Panel:MakePopup()
		ui.F4Panel:SetKeyboardInputEnabled(false)
	end
end

local function hideF4()
	if IsValid(ui.F4Panel) then ui.F4Panel:Hide() end
end

local function toggleF4()
	if IsValid(ui.F4Panel) and ui.F4Panel:IsVisible() then
		hideF4()
	else
		showF4()
	end
end

hook.Add("InitPostEntity", "MUI_Initialize", function()
	setupChatHook()

	if FAdmin and FAdmin.ScoreBoard then
		FAdmin.ScoreBoard.Show = function() end
		FAdmin.ScoreBoard.Hide = function() end
	end

	if DarkRP then
		DarkRP.openF4Menu = showF4
		DarkRP.closeF4Menu = hideF4
		DarkRP.toggleF4Menu = toggleF4
	end
end)

timer.Create("MUI_InitPoll", 1, 10, function()
	if not DarkRP then return end

	if not ui._f4Override then
		DarkRP.openF4Menu = showF4
		DarkRP.closeF4Menu = hideF4
		DarkRP.toggleF4Menu = toggleF4
		ui._f4Override = true
	end

	if not ui._chatReady then
		setupChatHook()
		ui._chatReady = true
	end
end)
