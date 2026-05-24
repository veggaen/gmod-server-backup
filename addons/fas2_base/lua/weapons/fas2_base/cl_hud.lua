--[[
	FAS2 CS2-Grade HUD
	Three-Layer Visual Layer — decoupled from RecoilBrain and BallisticLayer

	Normal play: static crosshair + predictive recoil dot ONLY
	ADS: crosshair fades, T-style, subtle range readout
	Inspect/Reload: full info (handled by Draw3D2DCamera in cl_model.lua)
]]

-- ============================================================
-- PERFORMANCE: Localize EVERYTHING at file scope
-- ============================================================
local FrameTime, CurTime, ScrW, ScrH = FrameTime, CurTime, ScrW, ScrH
local Lerp = Lerp
local math_Round  = math.Round
local math_Clamp  = math.Clamp
local math_min    = math.min
local math_max    = math.max
local math_abs    = math.abs
local math_floor  = math.floor
local surface      = surface
local draw         = draw

-- ============================================================
-- CONVARS: Created once, cached as objects (no string lookup per frame)
-- ============================================================
CreateClientConVar("fas2_xhair_style",          "1",   true, true)
CreateClientConVar("fas2_xhair_r",              "0",   true, true)
CreateClientConVar("fas2_xhair_g",              "255", true, true)
CreateClientConVar("fas2_xhair_b",              "0",   true, true)
CreateClientConVar("fas2_xhair_alpha",          "200", true, true)
CreateClientConVar("fas2_xhair_size",           "5",   true, true)
CreateClientConVar("fas2_xhair_thickness",      "1",   true, true)
CreateClientConVar("fas2_xhair_gap",            "4",   true, true)
CreateClientConVar("fas2_xhair_dot",            "0",   true, true)
CreateClientConVar("fas2_xhair_dot_size",       "1",   true, true)
CreateClientConVar("fas2_xhair_outline",        "1",   true, true)
CreateClientConVar("fas2_xhair_outline_thick",  "1",   true, true)
CreateClientConVar("fas2_xhair_t_style",        "0",   true, true)
CreateClientConVar("fas2_xhair_dynamic",        "0",   true, true)
CreateClientConVar("fas2_xhair_recoil",         "1",   true, true)
CreateClientConVar("fas2_xhair_recoil_r",       "255", true, true)
CreateClientConVar("fas2_xhair_recoil_g",       "255", true, true)
CreateClientConVar("fas2_xhair_recoil_b",       "255", true, true)
CreateClientConVar("fas2_xhair_recoil_alpha",   "50",  true, true)
CreateClientConVar("fas2_xhair_recoil_size",    "3",   true, true)
CreateClientConVar("fas2_xhair_ads_alpha",      "0",   true, true)
CreateClientConVar("fas2_xhair_recoil_dynamic", "1",   true, true)
CreateClientConVar("fas2_ads_recoil_guide",     "1",   true, true)
CreateClientConVar("fas2_ads_recoil_guide_alpha", "135", true, true)
CreateClientConVar("fas2_ads_recoil_guide_size", "3",  true, true)

local cv = {}
local function CacheCV(name)
	local obj = GetConVar(name)
	if obj then cv[name] = obj end
	return obj
end

local function CV(name)
	local obj = cv[name]
	return obj and obj:GetFloat() or 0
end

local function CVI(name)
	local obj = cv[name]
	return obj and obj:GetInt() or 0
end

timer.Simple(0, function()
	local names = {
		"fas2_xhair_style", "fas2_xhair_r", "fas2_xhair_g", "fas2_xhair_b",
		"fas2_xhair_alpha", "fas2_xhair_size", "fas2_xhair_thickness",
		"fas2_xhair_gap", "fas2_xhair_dot", "fas2_xhair_dot_size",
		"fas2_xhair_outline", "fas2_xhair_outline_thick", "fas2_xhair_t_style",
		"fas2_xhair_dynamic", "fas2_xhair_recoil", "fas2_xhair_recoil_r",
		"fas2_xhair_recoil_g", "fas2_xhair_recoil_b", "fas2_xhair_recoil_alpha",
		"fas2_xhair_recoil_size", "fas2_xhair_ads_alpha", "fas2_xhair_recoil_dynamic",
		"fas2_ads_recoil_guide", "fas2_ads_recoil_guide_alpha",
		"fas2_ads_recoil_guide_size", "fas2_nohud",
	}
	for _, n in ipairs(names) do CacheCV(n) end
end)

-- ============================================================
-- TEXTURES: Cached once
-- ============================================================
local ClumpSpread = surface.GetTextureID("VGUI/clumpspread_ring")
local Deploy      = surface.GetTextureID("VGUI/bipod_deploy")
local UnDeploy    = surface.GetTextureID("VGUI/bipod_undeploy")
local HitMarkerTx = surface.GetTextureID("hud/hit")

-- ============================================================
-- REUSABLE OBJECTS: Zero per-frame allocation
-- ============================================================
local _td  = {}
local _trResult
local Green = Color(202, 255, 163, 255)
local White = Color(255, 255, 255, 255)
local Black = Color(0, 0, 0, 255)

-- Per-frame scratch (avoids Color() allocation in hot path)
local _xhairColor   = Color(0, 255, 0, 200)
local _outlineColor = Color(0, 0, 0, 200)
local _dotColor     = Color(255, 255, 255, 80)

-- Circle polygon cache for the recoil dot (built once, reused every frame)
local _circleSegs = 16
local _circlePolys = {}
for i = 1, _circleSegs do
	_circlePolys[i] = {x = 0, y = 0}
end

local function DrawCircle(cx, cy, radius, r, g, b, a)
	local step = math.pi * 2 / _circleSegs
	for i = 1, _circleSegs do
		local ang = (i - 1) * step
		_circlePolys[i].x = cx + math.cos(ang) * radius
		_circlePolys[i].y = cy + math.sin(ang) * radius
	end
	draw.NoTexture()
	surface.SetDrawColor(r, g, b, a)
	surface.DrawPoly(_circlePolys)
end

-- ============================================================
-- DRAWING HELPERS (inlined for speed, no table/closure creation)
-- ============================================================
local function DrawOutline(cx, cy, w, h, thick, a)
	_outlineColor.a = a
	surface.SetDrawColor(_outlineColor)
	surface.DrawRect(cx - thick, cy - thick, w + thick * 2, h + thick * 2)
end

local function DrawLine(cx, cy, w, h, r, g, b, a, doOutline, outThick)
	if doOutline then
		DrawOutline(cx, cy, w, h, outThick, a)
	end
	surface.SetDrawColor(r, g, b, a)
	surface.DrawRect(cx, cy, w, h)
end

-- ============================================================
-- MAIN HUD ENTRY
-- ============================================================
function SWEP:DrawHUD()
	if CV("fas2_nohud") > 0 then return end

	local FT = FrameTime()
	local CT = CurTime()
	local scrW, scrH = ScrW(), ScrH()
	local cx = math_Round(scrW * 0.5)
	local cy = math_Round(scrH * 0.5)
	local lp = self.Owner:ShouldDrawLocalPlayer()
	local adsFrac = self.GetAdsFrac and self:GetAdsFrac() or (self.dt.Status == FAS_STAT_ADS and 1 or 0)

	-- ========================================================
	-- RECOIL DOT: shows current spray state (CS2 behavior)
	-- Snaps instantly on fire, smooths back to center on reset
	-- ========================================================
	local rawRX, rawRY = cx, cy
	if self.GetNextBulletScreenPos then
		rawRX, rawRY = self:GetNextBulletScreenPos()
	end

	local curIdx = self.PatternIndex or 0
	self._prevPatternIdx = curIdx

	if not self._dotInitialized then
		self.SmoothedRecoilX = rawRX
		self.SmoothedRecoilY = rawRY
		self._dotInitialized = true
	else
		local resetWin = self.GetEffectiveSprayResetTime and self:GetEffectiveSprayResetTime() or (self.SprayResetTime or 0.35)
		local returning = curIdx == 0 or (CT - (self.LastFireTime or 0)) > resetWin
		if returning then
			local returnSpeed = 10 + (4.5 - 10) * adsFrac
			-- Return toward screen center (crosshair). Faster than the old
			-- FT*4 because the user wants the dot to settle back onto the
			-- crosshair quickly after they stop firing — feels responsive.
			self.SmoothedRecoilX = Lerp(FT * returnSpeed, self.SmoothedRecoilX, cx)
			self.SmoothedRecoilY = Lerp(FT * returnSpeed, self.SmoothedRecoilY, cy)
		else
			-- Active spray: snap fast to next bullet position
			self.SmoothedRecoilX = Lerp(FT * 45, self.SmoothedRecoilX, rawRX)
			self.SmoothedRecoilY = Lerp(FT * 45, self.SmoothedRecoilY, rawRY)
		end
	end
	local dotX = math_Round(self.SmoothedRecoilX)
	local dotY = math_Round(self.SmoothedRecoilY)

	-- ========================================================
	-- STATE DETECTION
	-- ========================================================
	local isADS       = self.dt.Status == FAS_STAT_ADS
	local isSprint    = self.dt.Status == FAS_STAT_SPRINT
	local isCustomize = self.dt.Status == FAS_STAT_CUSTOMIZE
	local isGrenade   = self.dt.Status == FAS_STAT_QUICKGRENADE
	local isSafe      = self.FireMode == "safe"
	local isReloading = self.MagCheck == true
	local hideAll     = (isSprint or isCustomize or isGrenade or self.NearWall or self.Vehicle) and not lp or isSafe

	-- ========================================================
	-- ALPHA INTERPOLATION (smooth show/hide)
	-- ========================================================
	local adsAlpha = self.AllowADSHUDCrosshair and CV("fas2_xhair_ads_alpha") or 0

	if hideAll then
		self.CrossAlpha = Lerp(FT * 12, self.CrossAlpha, 0)
	elseif isADS and not lp then
		self.CrossAlpha = Lerp(FT * 12, self.CrossAlpha, adsAlpha)
	else
		self.CrossAlpha = Lerp(FT * 12, self.CrossAlpha, 255)
	end

	-- ========================================================
	-- GRENADE HUD (existing behavior, preserved)
	-- ========================================================
	if isGrenade then
		surface.SetDrawColor(0, 0, 0, 255 - self.CrossAlpha)
		surface.SetTexture(ClumpSpread)
		surface.DrawTexturedRect(dotX - 20, dotY - 20, 40, 40)
		surface.SetDrawColor(255, 255, 255, 255 - self.CrossAlpha)
		surface.DrawTexturedRect(dotX - 19, dotY - 19, 38, 38)
		White.a = 255 - self.CrossAlpha
		Black.a = 255 - self.CrossAlpha
		draw.ShadowText(self.Owner:GetAmmoCount("M67 Grenades") .. "x M67", "FAS2_HUD24", scrW * 0.5, scrH * 0.5 + 200, White, Black, 2, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	-- ========================================================
	-- CLUMP SPREAD (shotgun pattern indicator, preserved)
	-- ========================================================
	if self.ClumpSpread then
		local size = math.ceil(self.ClumpSpread * 2500)
		surface.SetDrawColor(0, 0, 0, self.CrossAlpha)
		surface.SetTexture(ClumpSpread)
		surface.DrawTexturedRect(dotX - size * 0.5 - 1, dotY - size * 0.5 - 1, size + 2, size + 2)
		surface.SetDrawColor(255, 255, 255, self.CrossAlpha)
		surface.DrawTexturedRect(dotX - size * 0.5, dotY - size * 0.5, size, size)
	end

	-- ========================================================
	-- STATIC CROSSHAIR (screen center, never moves)
	-- ========================================================
	local style       = CVI("fas2_xhair_style")
	local xr          = CVI("fas2_xhair_r")
	local xg          = CVI("fas2_xhair_g")
	local xb          = CVI("fas2_xhair_b")
	local xa          = math_min(CVI("fas2_xhair_alpha"), math_floor(self.CrossAlpha))
	local lineLen     = CVI("fas2_xhair_size")
	local thick       = math_max(CVI("fas2_xhair_thickness"), 1)
	local gap         = CVI("fas2_xhair_gap")
	local showDot     = CVI("fas2_xhair_dot")
	local dotSize     = math_max(CVI("fas2_xhair_dot_size"), 1)
	local doOutline   = CVI("fas2_xhair_outline") > 0
	local outThick    = math_max(CVI("fas2_xhair_outline_thick"), 1)
	local tStyleBase  = CVI("fas2_xhair_t_style") > 0
	local adsTStyle = isADS and not lp
	local halfThick = math_floor(thick * 0.5)

	if style >= 1 and xa > 1 then
		if style == 1 or style == 2 then
			-- Left
			DrawLine(cx - gap - lineLen, cy - halfThick, lineLen, thick, xr, xg, xb, xa, doOutline, outThick)
			-- Right
			DrawLine(cx + gap + 1, cy - halfThick, lineLen, thick, xr, xg, xb, xa, doOutline, outThick)
			-- Top (skip if T-style)
			if not tStyleBase and not adsTStyle then
				DrawLine(cx - halfThick, cy - gap - lineLen, thick, lineLen, xr, xg, xb, xa, doOutline, outThick)
			end
			-- Bottom (hide during ADS for iron sight blend)
			if not adsTStyle then
				DrawLine(cx - halfThick, cy + gap + 1, thick, lineLen, xr, xg, xb, xa, doOutline, outThick)
			end
		end

		if style == 2 or style == 3 or showDot > 0 then
			local ds = dotSize
			if doOutline then
				DrawOutline(cx - ds, cy - ds, ds * 2 + 1, ds * 2 + 1, outThick, xa)
			end
			surface.SetDrawColor(xr, xg, xb, xa)
			surface.DrawRect(cx - ds, cy - ds, ds * 2 + 1, ds * 2 + 1)
		end
	end

	-- ========================================================
	-- FOLLOW-RECOIL DOT (predictive — shows where next bullet goes)
	-- Accuracy-aware: green when accurate, red when inaccurate
	-- Hidden during pattern editor test/capture: the editor draws
	-- its own indicators and the live dot is misleading there.
	-- ========================================================
	local followRecoil = CVI("fas2_xhair_recoil")
	local inEditorSession = FAS2PatternEditor and FAS2PatternEditor.ClientState
		and FAS2PatternEditor.ClientState.active or false

	-- ADS used to be a hard gate that hid the dot the instant the status flag
	-- flipped. Replace with a continuous fade via GetAdsFrac so the dot eases
	-- out (and back in) over the same 180ms ADS<->hip transition the camera
	-- and recoil math use — no more visible pop when toggling mid-spray.
	local hipMix = 1 - adsFrac

	if followRecoil > 0 and hipMix > 0.001 and not inEditorSession and self.CrossAlpha > 1 then
		local rs = CVI("fas2_xhair_recoil_size")
		local ra = math_min(CVI("fas2_xhair_recoil_alpha"), math_floor(self.CrossAlpha))
		ra = math_floor(ra * hipMix)

		local dotDist = math.sqrt((dotX - cx) * (dotX - cx) + (dotY - cy) * (dotY - cy))
		local resetWin = self.GetEffectiveSprayResetTime and self:GetEffectiveSprayResetTime() or (self.SprayResetTime or 0.35)
		local returning = (self.PatternIndex or 0) == 0 or (CT - (self.LastFireTime or 0)) > resetWin
		if returning and dotDist < 3 then
			ra = math_floor(ra * math.Clamp(dotDist / 3, 0, 1))
		end
		if ra >= 2 then

		local dynColor = CVI("fas2_xhair_recoil_dynamic") > 0

		local dr, dg, db
		if dynColor and self.GetMovementAccuracy then
			local moveAcc = self:GetMovementAccuracy()
			if moveAcc <= 1.0 then
				-- Perfect: bright green
				dr, dg, db = 0, 255, 100
			elseif moveAcc <= 1.3 then
				-- Good: green fading to yellow
				local t = (moveAcc - 1.0) / 0.3
				dr = math_floor(255 * t)
				dg = 255
				db = math_floor(100 * (1 - t))
			elseif moveAcc <= 2.0 then
				-- Bad: yellow to red
				local t = (moveAcc - 1.3) / 0.7
				dr = 255
				dg = math_floor(255 * (1 - t))
				db = 0
			else
				-- Terrible: red
				dr, dg, db = 255, 60, 60
			end
		else
			dr = CVI("fas2_xhair_recoil_r")
			dg = CVI("fas2_xhair_recoil_g")
			db = CVI("fas2_xhair_recoil_b")
		end

		if rs <= 0 then
			surface.SetDrawColor(dr, dg, db, math_floor(ra * 0.7))
			surface.DrawRect(dotX, dotY, 2, 2)
		else
			if doOutline then
				DrawCircle(dotX, dotY, rs + 1, 0, 0, 0, math_floor(ra * 0.4))
			end
			DrawCircle(dotX, dotY, rs, dr, dg, db, ra)
		end

		end -- ra >= 2
	end

	-- ADS GUIDE: small next-bullet marker for ironsights/scopes. Hipfire keeps
	-- the existing dot; ADS gets this calmer guide so the player can read the
	-- compensation direction without the camera doing all the work.
	if followRecoil > 0 and CVI("fas2_ads_recoil_guide") > 0 and adsFrac > 0.05 and not inEditorSession and not lp then
		local dotDist = math.sqrt((dotX - cx) * (dotX - cx) + (dotY - cy) * (dotY - cy))
		local resetWin = self.GetEffectiveSprayResetTime and self:GetEffectiveSprayResetTime() or (self.SprayResetTime or 0.35)
		local recentlyFired = (CT - (self.LastFireTime or 0)) <= resetWin * 2.2
		if recentlyFired or dotDist > 2 then
			local gs = math_max(CVI("fas2_ads_recoil_guide_size"), 1)
			local ga = math_floor(math_min(CVI("fas2_ads_recoil_guide_alpha"), 220) * adsFrac)
			if dotDist < 3 and not recentlyFired then
				ga = math_floor(ga * math.Clamp(dotDist / 3, 0, 1))
			end
			if ga >= 2 then
				local lineAlpha = math_floor(ga * math.Clamp(dotDist / 36, 0.15, 0.55))
				surface.SetDrawColor(0, 0, 0, math_floor(lineAlpha * 0.55))
				surface.DrawLine(cx + 1, cy + 1, dotX + 1, dotY + 1)
				surface.SetDrawColor(110, 255, 150, lineAlpha)
				surface.DrawLine(cx, cy, dotX, dotY)
				DrawCircle(dotX, dotY, gs + 1, 0, 0, 0, math_floor(ga * 0.45))
				DrawCircle(dotX, dotY, gs, 110, 255, 150, ga)
				surface.SetDrawColor(110, 255, 150, math_floor(ga * 0.75))
				surface.DrawRect(dotX - 1, dotY - 1, 3, 3)
			end
		end
	end

	-- ========================================================
	-- MOVEMENT ACCURACY INDICATOR (subtle bar, only when moving badly)
	-- ========================================================
	if self.CrossAlpha > 5 and self.GetMovementAccuracy then
		local moveAcc = self:GetMovementAccuracy()
		if moveAcc > 1.3 then
			local moveAlpha = math_min(self.CrossAlpha, math_Clamp((moveAcc - 1.3) * 180, 0, 120))
			local barW = math_Clamp((moveAcc - 1) * 6, 0, 16)
			surface.SetDrawColor(0, 0, 0, moveAlpha * 0.5)
			surface.DrawRect(cx - 9, cy + 16, 18, 2)
			local accG = math_max(255 - math_floor((moveAcc - 1) * 180), 0)
			surface.SetDrawColor(255, accG, 0, moveAlpha)
			surface.DrawRect(cx - math_floor(barW * 0.5), cy + 16, barW, 1)
		end
	end

	-- ========================================================
	-- RANGE READOUT (minimal — only during ADS, bottom-right corner)
	-- ========================================================
	self._rangeAlpha = self._rangeAlpha or 0

	if isADS and not lp then
		self._rangeAlpha = Lerp(FT * 8, self._rangeAlpha, 110)
	else
		self._rangeAlpha = Lerp(FT * 6, self._rangeAlpha, 0)
	end

	if self._rangeAlpha > 2 then
		_td.start = self.Owner:GetShootPos()
		_td.endpos = _td.start + self.Owner:EyeAngles():Forward() * 16384
		_td.filter = self.Owner
		_trResult = util.TraceLine(_td)

		local aimDist   = _trResult.HitPos:Distance(_td.start)
		local effRange  = self.EffectiveRange or 3000
		local distM     = math_Round(aimDist * 0.0254)
		local effM      = math_Round(effRange * 0.0254)
		local dropCm    = math_Round((self.GetBallisticOffsetAtDistance and self:GetBallisticOffsetAtDistance(aimDist) or 0) * 2.54)

		local rFrac = math_Clamp(aimDist / effRange, 0, 2)
		local rR, rG
		if rFrac <= 1 then
			rR = math_floor(rFrac * 255)
			rG = 255
		else
			rR = 255
			rG = math_floor(math_max(255 - (rFrac - 1) * 255, 0))
		end

		local rA = math_floor(self._rangeAlpha)
		local bgA = math_floor(rA * 0.6)

		draw.ShadowText(
			distM .. "m / " .. effM .. "m",
			"FAS2_HUD24", scrW - 20, scrH - 60,
			Color(rR, rG, 0, rA), Color(0, 0, 0, bgA),
			1, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM
		)

		if dropCm > 2 then
			draw.ShadowText(
				"-" .. dropCm .. "cm drop",
				"FAS2_HUD24", scrW - 20, scrH - 36,
				Color(200, 160, 80, math_floor(rA * 0.8)), Color(0, 0, 0, bgA),
				1, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM
			)
		elseif dropCm < -2 then
			draw.ShadowText(
				"+" .. math.abs(dropCm) .. "cm rise",
				"FAS2_HUD24", scrW - 20, scrH - 36,
				Color(120, 190, 255, math_floor(rA * 0.8)), Color(0, 0, 0, bgA),
				1, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM
			)
		end
	end

	-- ========================================================
	-- PROFICIENCY TEXT (existing behavior, preserved)
	-- ========================================================
	if CT < self.ProficientTextTime then
		self.ProficientAlpha = Lerp(FT * 10, self.ProficientAlpha, 255)
	else
		self.ProficientAlpha = Lerp(FT * 10, self.ProficientAlpha, 0)
	end

	if self.ProficientAlpha > 2 then
		White.a = self.ProficientAlpha
		Black.a = self.ProficientAlpha
		Green.a = self.ProficientAlpha
		draw.ShadowText("You've become proficient with this weapon.", "FAS2_HUD36", scrW * 0.5, scrH * 0.5 - 200, White, Black, 2, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.ShadowText("Reload speed increased.", "FAS2_HUD24", scrW * 0.5, scrH * 0.5 - 170, Green, Black, 2, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.ShadowText("Weapon bolting speed increased.", "FAS2_HUD24", scrW * 0.5, scrH * 0.5 - 145, Green, Black, 2, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	White.a = 255
	Black.a = 255

	-- ========================================================
	-- BIPOD PROMPTS (existing behavior, preserved)
	-- ========================================================
	if self.dt.Status ~= FAS_STAT_CUSTOMIZE then
		if self.InstalledBipod then
			if not self.dt.Bipod then
				if self:CanDeployBipod() then
					draw.ShadowText("[USE KEY]", "FAS2_HUD24", scrW * 0.5, scrH * 0.5 + 100, White, Black, 2, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
					surface.SetTexture(Deploy)
					surface.SetDrawColor(0, 0, 0, 255)
					surface.DrawTexturedRect(scrW * 0.5 - 47, scrH * 0.5 + 126, 96, 96)
					surface.SetDrawColor(255, 255, 255, 255)
					surface.DrawTexturedRect(scrW * 0.5 - 48, scrH * 0.5 + 125, 96, 96)
				end
			else
				draw.ShadowText("[USE KEY]", "FAS2_HUD24", scrW * 0.5, scrH * 0.5 + 100, White, Black, 2, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				surface.SetTexture(UnDeploy)
				surface.SetDrawColor(0, 0, 0, 255)
				surface.DrawTexturedRect(scrW * 0.5 - 47, scrH * 0.5 + 126, 96, 96)
				surface.SetDrawColor(255, 255, 255, 255)
				surface.DrawTexturedRect(scrW * 0.5 - 48, scrH * 0.5 + 125, 96, 96)
			end
		end
	end

	-- ========================================================
	-- HIT MARKER (existing behavior, preserved at dot position)
	-- ========================================================
	local hmKind = self.HitMarkerKind or "body"
	local hmCol  = color_white
	if hmKind == "head" then
		hmCol = Color(255, 230, 110) -- gold
	elseif hmKind == "kill" then
		hmCol = Color(255, 90, 90)   -- red
	end

	surface.SetTexture(HitMarkerTx)
	surface.SetDrawColor(0, 0, 0, self.HitMarkerAlpha)
	surface.DrawTexturedRect(dotX - 33, dotY - 33, 66, 66)
	surface.SetDrawColor(hmCol.r, hmCol.g, hmCol.b, self.HitMarkerAlpha)
	surface.DrawTexturedRect(dotX - 32, dotY - 32, 64, 64)

	if CT > self.HitMarkerTime then
		self.HitMarkerAlpha = math.Approach(self.HitMarkerAlpha, 0, FT * 1400)
	end
end
