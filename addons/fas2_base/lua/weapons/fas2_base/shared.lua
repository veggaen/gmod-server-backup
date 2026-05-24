if SERVER then
	AddCSLuaFile("shared.lua")
	AddCSLuaFile("cl_drawfuncs.lua")
	AddCSLuaFile("cl_model.lua")
	AddCSLuaFile("cl_umsgs.lua")
	AddCSLuaFile("cl_hud.lua")
	AddCSLuaFile("sh_bullet.lua")
	AddCSLuaFile("cl_calcview.lua")
	AddCSLuaFile("cl_muzzleflash.lua")
	AddCSLuaFile("cl_attachments.lua")
	AddCSLuaFile("cl_cmodel_manager.lua")

	include("sv_attachments.lua")

	umsg.PoolString("FAS2_SUPPRESSMODEL")
	umsg.PoolString("FAS2_UNSUPPRESSMODEL")
end

include("sh_bullet.lua")

if CLIENT then
	include("cl_model.lua")
	include("cl_umsgs.lua")
	include("cl_hud.lua")
	include("cl_calcview.lua")
	include("cl_muzzleflash.lua")
	include("cl_drawfuncs.lua")
	include("cl_attachments.lua")
	include("cl_cmodel_manager.lua")

	SWEP.BounceWeaponIcon = false
	SWEP.PitchMod = 1
	SWEP.YawMod = 1
	SWEP.CrossAlpha = 255
	SWEP.CheckTime = 0
	SWEP.CrossAlpha = 255
	SWEP.CrossAmount = 0
	SWEP.CurFOVMod = 0
	SWEP.AngleDelta = Angle(0, 0, 0)
	SWEP.OldDelta = Angle(0, 0, 0)
	SWEP.ProficientTextTime = 0
	SWEP.ProficientAlpha = 0
	SWEP.CockRemindTime = 0
	SWEP.CockRemindAlpha = 0
	SWEP.MouseSensMod = 1
	SWEP.DeployAnimSpeed = 1
	SWEP.CurAnim = "none"
	SWEP.BoltReminderText = "RELOAD KEY - BOLT WEAPON"
    SWEP.PrintName = ""
    SWEP.Slot = 3
    SWEP.SlotPos = 3
    SWEP.DrawAmmo = false
    SWEP.DrawCrosshair = false
	SWEP.MoveType = 1
	SWEP.ReloadCycleTime = 0.9
	SWEP.ShowStats = false
	SWEP.WMAng = Vector(0, 0, 0)
	SWEP.WMPos = Vector(0, 0, 0)
	SWEP.Text3DForward = -4
	SWEP.Text3DRight = -2
	SWEP.Text3DSize = 0.015
	SWEP.WMScale = 1
	SWEP.BlurAmount = 0
	SWEP.HitMarkerAlpha = 0
	SWEP.HitMarkerTime = 0
	SWEP.MagText = "MAG "
	SWEP.FireModeSwitchTime = 0
	SWEP.ReloadRestartLockout = 0.22
	SWEP.SwayInterpolation = "dynamic"

	surface.CreateFont("FAS2_HUD72", {font = "Default", size = 72, weight = 700, blursize = 0, antialias = true, shadow = false})
	surface.CreateFont("FAS2_HUD48", {font = "Default", size = 48, weight = 700, blursize = 0, antialias = true, shadow = false})
	surface.CreateFont("FAS2_HUD36", {font = "Default", size = 36, weight = 700, blursize = 0, antialias = true, shadow = false})
	surface.CreateFont("FAS2_HUD28", {font = "Default", size = 28, weight = 700, blursize = 0, antialias = true, shadow = false})
	surface.CreateFont("FAS2_HUD24", {font = "Default", size = 24, weight = 700, blursize = 0, antialias = true, shadow = false})

	SWEP.CurSoundTable = nil
	SWEP.CurSoundEntry = nil
	SWEP.HideWorldModel = true

	SWEP.CustomizePos = Vector(5.657, -1.688, -2.027)
	SWEP.CustomizeAng = Vector(14.647, 30.319, 15.295)
	SWEP.BipodPos = Vector(0, 0, 0)
	SWEP.BipodAng = Vector(0, 0, 0)
	SWEP.PistolSafePos = Vector(0, 0, 1.203)
	SWEP.PistolSafeAng = Vector(-15.125, 0, 0)
	SWEP.RifleSafePos = Vector(0.324, 0.092, -0.621)
	SWEP.RifleSafeAng = Vector(-8.941, 7.231, -9.535)
	SWEP.BipodMoveTime = 0
	SWEP.SafePosType = "rifle"
end

SWEP.AimSounds = {"weapons/weapon_sightlower.wav", "weapons/weapon_sightlower2.wav"}
SWEP.BackToHipSounds = {"weapons/weapon_sightraise.wav", "weapons/weapon_sightraise2.wav"}
SWEP.EmptySound = Sound("weapons/empty_submachineguns.wav")
SWEP.RunHoldType = "passive"
SWEP.ReloadState = 0
SWEP.BipodDelay = 0
SWEP.BurstFireDelayMod = 0.66
SWEP.ShotToDelayUntil = 0

SWEP.SpreadWait = 0
SWEP.AddSpread = 0
SWEP.AddSpreadSpeed = 1
SWEP.IsFAS2Weapon = true
SWEP.Events = {}

SWEP.SprintDelay = 0
SWEP.ReloadWait = 0
SWEP.MagCheckAlpha = 0
SWEP.ReloadProgress = 0
SWEP.Suppressed = false
SWEP.PenMod = 1

SWEP.PenetrationEnabled = true
SWEP.RicochetEnabled = true

SWEP.PatternIndex = 0
SWEP.SprayPattern = nil
SWEP.SprayResetTime = 0.35

-- Seconds for the ADS<->hip transition to ease 0..1. Every recoil/dot/camera
-- system blends through SWEP:GetAdsFrac() so behavior is continuous across
-- the switch instead of snapping at the boolean status flip.
SWEP.AdsTransitionTime = 0.18
SWEP.AdsAimSnapSmoothing = 1.0

-- ADS visual follow: 0 disables; 1 lets CalcView visually place the iron
-- sights over the next-bullet point during ADS. This used to physically
-- rotate EyeAngles, which preserved aim but felt jittery with wide sprays.
if SERVER then
	CreateConVar("fas2_ads_aim_snap", "1.0",
		FCVAR_ARCHIVE + FCVAR_NOTIFY + FCVAR_REPLICATED,
		"Master strength for ADS follow-recoil alignment. Client fas2_ads_camera_follow_strength controls how much of this moves the camera; the HUD guide remains readable.")

	-- Multiplier on every weapon's SprayResetTime. Lower = spray decays
	-- faster after the player stops firing (or pauses between shots), so
	-- semi-auto rapid-clicks land each round on the cursor instead of
	-- building deep into the recoil pattern. 1.0 = vanilla.
	CreateConVar("fas2_spray_reset_mul", "0.75",
		FCVAR_ARCHIVE + FCVAR_NOTIFY + FCVAR_REPLICATED,
		"Multiplier on SprayResetTime. <1 makes the spray pattern reset faster between shots/bursts. 1.0 = vanilla.")
end

SWEP.MuzzleVelocity = 18000

-- Per-weapon multiplier on the predicted ViewPunch kick (CS2-style camera
-- shake) applied in sh_bullet.lua. 1.0 = balanced default. Bump on snipers
-- and high-recoil rifles (e.g. AWP ~2.0, M14 ~1.4), lower on pistols/SMGs
-- (~0.7) so each gun feels distinct in the hand even when their patterns
-- already differ.
SWEP.ViewPunchScale = 1.0
SWEP.BulletDrop = true
SWEP.RecoilScale = 1.0
SWEP.LastFireTime = 0

FAS_STAT_IDLE = 0
FAS_STAT_ADS = 1
FAS_STAT_SPRINT = 2
FAS_STAT_HOLSTER = 3
FAS_STAT_CUSTOMIZE = 4
FAS_STAT_HOLSTER_START = 5
FAS_STAT_HOLSTER_END = 6
FAS_STAT_QUICKGRENADE = 7

SWEP.Author            = "Spy"
SWEP.Instructions    = "CONTEXT MENU KEY - Open customization menu\nCOMMA KEY - Change firemode\nUSE KEY + PRIMARY ATTACK KEY - Quick grenade"
SWEP.Contact        = ""
SWEP.Purpose        = ""
SWEP.HoldType = "ar2"
SWEP.FirstDeploy = true

SWEP.ViewModelFOV    = 55
SWEP.ViewModelFlip    = false

SWEP.Spawnable            = false
SWEP.AdminSpawnable        = false

SWEP.ViewModel      = "models/Items/AR2_Grenade.mdl"
SWEP.WorldModel   = ""

-- Primary Fire Attributes --
SWEP.Primary.ClipSize        = -1
SWEP.Primary.DefaultClip    = -1
SWEP.Primary.Automatic       = false
SWEP.Primary.Ammo             = "none"

-- Secondary Fire Attributes --
SWEP.Secondary.ClipSize        = -1
SWEP.Secondary.DefaultClip    = -1
SWEP.Secondary.Automatic = true --       = true
SWEP.Secondary.Ammo         = "none"

SWEP.FireModeNames = {["auto"] = {display = "FULL-AUTO", auto = true, burstamt = 0},
	["semi"] = {display = "SEMI-AUTO", auto = false, burstamt = 0},
	["double"] = {display = "DOUBLE-ACTION", auto = false, burstamt = 0},
	["bolt"] = {display = "BOLT-ACTION", auto = false, burstamt = 0},
	["pump"] = {display = "PUMP-ACTION", auto = false, burstamt = 0},
	["break"] = {display = "BREAK-ACTION", auto = false, burstamt = 0},
	["2burst"] = {display = "2-ROUND BURST", auto = true, burstamt = 2},
	["3burst"] = {display = "3-ROUND BURST", auto = true, burstamt = 3},
	["safe"] = {display = "SAFE", auto = false, burstamt = 0}}

local vm, t, a

function SWEP:SetupDataTables()
	self:DTVar("Int", 0, "Status")
	self:DTVar("Int", 1, "Shots")

	self:DTVar("Bool", 0, "Suppressed")
	self:DTVar("Bool", 1, "Bipod")
	self:DTVar("Bool", 2, "Holstered")
end

function SWEP:CalculateEffectiveRange()
	self.EffectiveRange = self.CaseLength * 10 - self.BulletLength * 5 -- setup realistic base effective range
	self.EffectiveRange = self.EffectiveRange * 39.37 -- convert meters to units
	self.EffectiveRange = self.EffectiveRange / 2
	self.DamageFallOff = (100 - (self.CaseLength - self.BulletLength)) / 200
	self.PenStr = (self.BulletLength * 0.5 + self.CaseLength * 0.35) * (self.PenAdd and self.PenAdd or 1)
end

local SP = game.SinglePlayer()
local reg = debug.getregistry()
local GetVelocity = reg.Entity.GetVelocity
local Length = reg.Vector.Length
local GetAimVector = reg.Player.GetAimVector

function SWEP:Initialize()
	self:SetWeaponHoldType(self.HoldType)

	self.CurCone = self.HipCone
	self.Class = self:GetClass()

	table.insert(self.FireModes, #self.FireModes + 1, "safe")
	t = self.FireModes[1]
	self.FireMode = t
	t = self.FireModeNames[t]

	self.Primary.Auto = t.auto
	self.BurstAmount = t.burstamt
	self.dt.Suppressed = self.Suppressed
	self:CalculateEffectiveRange()

	if FAS2_SprayPatterns and FAS2_SprayPatterns[self.Class] then
		self.SprayPattern = FAS2_SprayPatterns[self.Class]
	end

	if FAS2_MuzzleVelocity and FAS2_MuzzleVelocity[self.Class] then
		self.MuzzleVelocity = FAS2_MuzzleVelocity[self.Class]
	end

	if FAS2_RecoilScale and FAS2_RecoilScale[self.Class] then
		self.RecoilScale = FAS2_RecoilScale[self.Class]
	end

	if FAS2_SprayResetTime and FAS2_SprayResetTime[self.Class] then
		self.SprayResetTime = FAS2_SprayResetTime[self.Class]
	end

	if FAS2_ViewPunchScale and FAS2_ViewPunchScale[self.Class] then
		self.ViewPunchScale = FAS2_ViewPunchScale[self.Class]
	end

	if not self.SprayPattern then
		if GetConVar and GetConVar("fas2_debug") and GetConVar("fas2_debug"):GetBool() then
			print("[FAS2] WARNING: No spray pattern for " .. tostring(self.Class) .. " - RecoilScale: " .. tostring(self.RecoilScale))
		end
	elseif GetConVar and GetConVar("fas2_debug") and GetConVar("fas2_debug"):GetBool() then
		print("[FAS2] Loaded pattern for " .. tostring(self.Class) .. " (" .. #self.SprayPattern .. " entries, scale=" .. tostring(self.RecoilScale) .. ")")
	end

	self.Damage_Orig = self.Damage
	self.FireDelay_Orig = self.FireDelay
	self.HipCone_Orig = math.Round(self.HipCone, 4)
	self.AimCone_Orig = math.Round(self.AimCone, 4)
	self.Recoil_Orig = math.Round(self.Recoil, 4)
	self.SpreadPerShot_Orig = self.SpreadPerShot
	self.MaxSpreadInc_Orig = self.MaxSpreadInc
	self.VelocitySensitivity_Orig = self.VelocitySensitivity
	self.AimPosName = "AimPos"
	self.AimAngName = "AimAng"

	if not self.Owner.FAS_FamiliarWeapons then
		self.Owner.FAS_FamiliarWeapons = {}
	end

	if CLIENT then
		self.BlendPos = Vector(0, 0, 0)
		self.BlendAng = Vector(0, 0, 0)

		self.NadeBlendPos = Vector(0, 0, 0)
		self.NadeBlendAng = Vector(0, 0, 0)
		self.FireModeDisplay = t.display

		self.AimPos_Orig = self.AimPos
		self.AimAng_Orig = self.AimAng
		self.AimFOV_Orig = self.AimFOV
		self.ViewModelFOV_Orig = self.ViewModelFOV

		self.TargetViewModelFOV_Orig = self.TargetViewModelFOV
		self.TargetViewModelFOV = self.TargetViewModelFOV or self.ViewModelFOV

		if not self.Wep then
			self.Wep = self:createManagedCModel(self.VM, RENDERGROUP_BOTH)
			self.Wep:SetNoDraw(true)
		end

		if not self.W_Wep and self.WM then
			self.W_Wep = self:createManagedCModel(self.WM, RENDERGROUP_BOTH)
			self.W_Wep:SetNoDraw(true)
		end

		if not self.Nade then
			self.Nade = self:createManagedCModel("models/weapons/v_m67.mdl", RENDERGROUP_BOTH)
			self.Nade:SetNoDraw(true)
			self.Nade.LifeTime = 0
		end

		RunConsoleCommand("fas2_handrig_applynow")

		//CT = CurTime()

		//a = self.Anims.Draw_First

		//if type(a) == "table" then
		//	a = table.Random(a)
		//end

		//FAS2_PlayAnim(self, self.Anims.Draw_First, 1)

		--self:Deploy()
	end
end

local mag, CT, ang, cone, vel, ammo

function SWEP:CockLogic()
	if self.Owner.FAS_FamiliarWeapons[self.Class] then
		if self.dt.Status == FAS_STAT_ADS then
			if self.dt.Bipod then
				FAS2_PlayAnim(self, self.Anims.Cock_Bipod_Aim_Nomen)
			else
				FAS2_PlayAnim(self, self.Anims.Cock_Aim_Nomen)
			end

			self.Cocked = true
		else
			if self.dt.Bipod then
				FAS2_PlayAnim(self, self.Anims.Cock_Bipod_Nomen)
			else
				FAS2_PlayAnim(self, self.Anims.Cock_Nomen)
			end

			self.Cocked = true
		end

		if self.dt.Bipod then
			self:SetNextPrimaryFire(CT + self.CockTime_Bipod_Nomen)
			self:SetNextSecondaryFire(CT + self.CockTime_Bipod_Nomen)
			self.SprintWait = CT + self.CockTime_Bipod_Nomen
			self.ReloadWait = CT + self.CockTime_Bipod_Nomen
			self.BipodDelay = CT + self.CockTime_Bipod_Nomen
		else
			self:SetNextPrimaryFire(CT + self.CockTime_Nomen)
			self:SetNextSecondaryFire(CT + self.CockTime_Nomen)
			self.SprintWait = CT + self.CockTime_Nomen
			self.ReloadWait = CT + self.CockTime_Nomen
			self.BipodDelay = CT + self.CockTime_Nomen
		end
	else
		if self.dt.Status == FAS_STAT_ADS then
			if self.dt.Bipod then
				FAS2_PlayAnim(self, self.Anims.Cock_Bipod_Aim)
			else
				FAS2_PlayAnim(self, self.Anims.Cock_Aim)
			end

			self.Cocked = true
		else
			if self.dt.Bipod then
				FAS2_PlayAnim(self, self.Anims.Cock_Bipod)
			else
				FAS2_PlayAnim(self, self.Anims.Cock)
			end

			self.Cocked = true
		end

		if self.dt.Bipod then
			self:SetNextPrimaryFire(CT + self.CockTime_Bipod)
			self:SetNextSecondaryFire(CT + self.CockTime_Bipod)
			self.SprintWait = CT + self.CockTime_Bipod
			self.ReloadWait = CT + self.CockTime_Bipod
			self.BipodDelay = CT + self.CockTime_Bipod
		else
			self:SetNextPrimaryFire(CT + self.CockTime)
			self:SetNextSecondaryFire(CT + self.CockTime)
			self.SprintWait = CT + self.CockTime
			self.ReloadWait = CT + self.CockTime
			self.BipodDelay = CT + self.CockTime
		end
	end
end

function SWEP:AddEvent(time, func)
	table.insert(self.Events, {time = CurTime() + time, func = func})
end

function SWEP:CanAcceptReloadInput(ct)
	ct = ct or CurTime()

	if CLIENT and not IsFirstTimePredicted() then return false end
	if self.Owner:KeyDown(IN_ATTACK) then return false end
	if (self._nextReloadAccept or 0) > ct then return false end
	if self._fas2Reloading and self.ReloadDelay then return false end

	return true
end

function SWEP:MarkReloadStarted(ct)
	ct = ct or CurTime()
	self._fas2Reloading = true
	self._fas2ReloadStart = ct
	self._nextReloadAccept = math.max(self._nextReloadAccept or 0, ct + 0.12)
end

function SWEP:AbortReload()
	local ct = CurTime()
	if not self.ReloadDelay and (self.ReloadState or 0) == 0 and not self._fas2Reloading then
		return false
	end

	self.ReloadDelay = nil
	self.ReloadState = 0
	self.ReloadStateWait = 0
	self._fas2Reloading = false
	self._nextReloadAccept = ct + (self.ReloadRestartLockout or 0.22)
	self:SetNextPrimaryFire(ct + 0.12)
	self:SetNextSecondaryFire(ct + 0.12)
	self.ReloadWait = ct + 0.12

	if self.dt then
		self.dt.Status = FAS_STAT_IDLE
	end

	if self.Anims then
		local idle = self.Anims.Idle
		if idle then
			FAS2_PlayAnim(self, idle, 1, 0)
		end
	end

	return true
end

function SWEP:Reload()
	CT = CurTime()

	if not self:CanAcceptReloadInput(CT) then
		return
	end

	if CT < self.ReloadWait then
		return
	end

	if self.ReloadDelay and CT < self.ReloadDelay then
		return
	end

	if self.FireMode == "safe" then
		if SERVER and SP then
			SendUserMessage("FAS2_CHECKWEAPON", self.Owner)
		end

		if CLIENT then
			self.CheckTime = CT + 0.5
		end

		return
	end

	if self.dt.Status == FAS_STAT_ADS then
		return
	end

	if self.CockAfterShot and not self.Cocked then
		self:CockLogic()
	end

	mag = self:Clip1()

	if mag >= self.Primary.ClipSize or self.Owner:GetAmmoCount(self.Primary.Ammo) == 0 then
		if SERVER and SP then
			SendUserMessage("FAS2_CHECKWEAPON", self.Owner)
		end

		if CLIENT then
			self.CheckTime = CT + 0.5
		end

		return
	end

	if SERVER then
		self.dt.Status = FAS_STAT_IDLE
	end

	if mag == 0 then
		if self.Owner.FAS_FamiliarWeapons[self.Class] then
			if self.dt.Bipod then
				FAS2_PlayAnim(self, self.Anims.Reload_Bipod_Empty_Nomen)
				self.ReloadDelay = CT + self.ReloadTime_Bipod_Empty_Nomen + 0.3
				self:SetNextPrimaryFire(CT + self.ReloadTime_Bipod_Empty_Nomen + 0.3)
				self:SetNextSecondaryFire(CT + self.ReloadTime_Bipod_Empty_Nomen + 0.3)
			else
				FAS2_PlayAnim(self, self.Anims.Reload_Empty_Nomen)
				self.ReloadDelay = CT + self.ReloadTime_Empty_Nomen + 0.3
				self:SetNextPrimaryFire(CT + self.ReloadTime_Empty_Nomen + 0.3)
				self:SetNextSecondaryFire(CT + self.ReloadTime_Empty_Nomen + 0.3)
			end
		else
			if self.dt.Bipod then
				FAS2_PlayAnim(self, self.Anims.Reload_Bipod_Empty)
				self.ReloadDelay = CT + self.ReloadTime_Bipod_Empty + 0.3
				self:SetNextPrimaryFire(CT + self.ReloadTime_Bipod_Empty + 0.3)
				self:SetNextSecondaryFire(CT + self.ReloadTime_Bipod_Empty + 0.3)
			else
				FAS2_PlayAnim(self, self.Anims.Reload_Empty)
				self.ReloadDelay = CT + self.ReloadTime_Empty + 0.3
				self:SetNextPrimaryFire(CT + self.ReloadTime_Empty + 0.3)
				self:SetNextSecondaryFire(CT + self.ReloadTime_Empty + 0.3)
			end
		end
	else
		if self.Owner.FAS_FamiliarWeapons[self.Class] then
			if self.dt.Bipod then
				FAS2_PlayAnim(self, self.Anims.Reload_Bipod_Nomen)
				self.ReloadDelay = CT + self.ReloadTime_Bipod_Nomen + 0.3
				self:SetNextPrimaryFire(CT + self.ReloadTime_Bipod_Nomen + 0.3)
				self:SetNextSecondaryFire(CT + self.ReloadTime_Bipod_Nomen + 0.3)
			else
				FAS2_PlayAnim(self, self.Anims.Reload_Nomen)
				self.ReloadDelay = CT + self.ReloadTime_Nomen + 0.3
				self:SetNextPrimaryFire(CT + self.ReloadTime_Nomen + 0.3)
				self:SetNextSecondaryFire(CT + self.ReloadTime_Nomen + 0.3)
			end
		else
			if self.dt.Bipod then
				FAS2_PlayAnim(self, self.Anims.Reload_Bipod)
				self.ReloadDelay = CT + self.ReloadTime_Bipod + 0.3
				self:SetNextPrimaryFire(CT + self.ReloadTime_Bipod + 0.3)
				self:SetNextSecondaryFire(CT + self.ReloadTime_Bipod + 0.3)
			else
				FAS2_PlayAnim(self, self.Anims.Reload)
				self.ReloadDelay = CT + self.ReloadTime + 0.3
				self:SetNextPrimaryFire(CT + self.ReloadTime + 0.3)
				self:SetNextSecondaryFire(CT + self.ReloadTime + 0.3)
			end
		end
	end

	self.Owner:SetAnimation(PLAYER_RELOAD)
	self:MarkReloadStarted(CT)
end

function SWEP:PlayDeployAnim()
	if self:Clip1() == 0 and self.Anims.Draw_Empty then
		FAS2_PlayAnim(self, self.Anims.Draw_Empty, self.DeployAnimSpeed)
	else
		FAS2_PlayAnim(self, self.Anims.Draw, self.DeployAnimSpeed)
	end
end

function SWEP:Deploy()
	if not IsValid(self.Owner) then
		return false
	end

	self.PatternIndex = 0
	self._camAccP = 0
	self._camAccY = 0
	self._recoilAccP = 0
	self._recoilAccY = 0
	self._sprayLiftP = 0
	self._sprayLiftY = 0
	self._adsSnapTargetP = 0
	self._adsSnapTargetY = 0
	self._adsSnapAppliedP = 0
	self._adsSnapAppliedY = 0
	self._adsSnapLastFrac = nil
	self._adsSnapViewDeltaP = 0
	self._adsSnapViewDeltaY = 0

	if not self.FirstDeploy then
		CT = CurTime()

		if (CLIENT and not IsFirstTimePredicted()) then
			self:SetNextPrimaryFire(CT + (self.DeployTime and self.DeployTime or 1))
			self:SetNextSecondaryFire(CT + (self.DeployTime and self.DeployTime or 1))
			self.ReloadWait = CT + (self.DeployTime and self.DeployTime or 1)
			self.SprintDelay = CT + (self.DeployTime and self.DeployTime or 1)
		else
			self:SetNextPrimaryFire(CT + (self.DeployTime and self.DeployTime or 1))
			self:SetNextSecondaryFire(CT + (self.DeployTime and self.DeployTime or 1))
			self.ReloadWait = CT + (self.DeployTime and self.DeployTime or 1)
			self.SprintDelay = CT + (self.DeployTime and self.DeployTime or 1)
		end

		self:PlayDeployAnim()
	else
		if SP and SERVER then
			a = self.Anims.Draw_First

			if type(a) == "table" then
				a = table.Random(a)
			end

			FAS2_PlayAnim(self, a, 1, 0, self.Owner:Ping() / 1000)
		end

		//self.CurSoundTable = self.Sounds[a]
		//self.CurSoundEntry = 1
		//self.SoundSpeed = 1
		//self.SoundTime = CT + 0.175 + self:GetOwner():Ping() / 1000
		//self.CurAnim = a

		CT = CurTime()

		self:SetNextPrimaryFire(CT + (self.FirstDeployTime and self.FirstDeployTime or 1))
		self:SetNextSecondaryFire(CT + (self.FirstDeployTime and self.FirstDeployTime or 1))
		self.ReloadWait = CT + (self.FirstDeployTime and self.FirstDeployTime or 1)
		self.SprintDelay = CT + (self.FirstDeployTime and self.FirstDeployTime or 1)
		self.FirstDeploy = false
	end

	if CLIENT then
		self.Peeking = false
	end

	if not self.Owner.FAS_FamiliarWeapons then
		self.Owner.FAS_FamiliarWeapons = {}
	end

	if SERVER then
		if not self.Owner.FAS_FamiliarWeaponsProgress then
			self.Owner.FAS_FamiliarWeaponsProgress = {}
		end
	end

	self.dt.Status = FAS_STAT_IDLE
	self:EmitSound("weapons/weapon_deploy" .. math.random(1, 3) .. ".wav", 50, 100)

	return true
end

function SWEP:CycleFiremodes()
	CT = CurTime()
	t = self.FireModes

	if not t.last then
		t.last = 2
	else
		if not t[t.last + 1] then
			t.last = 1
		else
			t.last = t.last + 1
		end
	end

	if self.dt.Status == FAS_STAT_ADS then
		if self.FireModes[t.last] == "safe" then
			t.last = 1
		end
	end

	if self.FireMode != self.FireModes[t.last] and self.FireModes[t.last] then
		self:SelectFiremode(self.FireModes[t.last])
		self:SetNextPrimaryFire(CT + 0.25)
		self:SetNextSecondaryFire(CT + 0.25)
		self.ReloadWait = CT + 0.25
	end
end

function SWEP:DelayMe(t)
	t = t + 0.1
	self:SetNextPrimaryFire(t)
	self:SetNextSecondaryFire(t)
	self.ReloadWait = t
end

function SWEP:SelectFiremode(n)
	CT = CurTime()

	if CLIENT then
		return
	end

	t = self.FireModeNames[n]
	self.Primary.Automatic = t.auto
	self.FireMode = n
	self.BurstAmount = t.burstamt

	if self.FireMode == "safe" then
		self.dt.Holstered = true -- more reliable than umsgs
	else
		self.dt.Holstered = false
	end

	umsg.Start("FAS2_FIREMODE")
		umsg.Entity(self.Owner)
		umsg.String(n)
	umsg.End()
end

function SWEP:PlayHolsterAnim()
	if self:Clip1() == 0 and self.Anims.Holster_Empty then
		FAS2_PlayAnim(self, self.Anims.Holster_Empty)
	else
		FAS2_PlayAnim(self, self.Anims.Holster)
	end
end

function SWEP:Holster(wep)
	if self == wep then
		return
	end

	self.PatternIndex = 0
	self._sprayLiftP = 0
	self._sprayLiftY = 0
	self._adsSnapTargetP = 0
	self._adsSnapTargetY = 0
	self._adsSnapAppliedP = 0
	self._adsSnapAppliedY = 0
	self._adsSnapLastFrac = nil
	self._adsSnapViewDeltaP = 0
	self._adsSnapViewDeltaY = 0

	if self.dt.Status == FAS_STAT_HOLSTER_END then
		self.dt.Status = FAS_STAT_IDLE
		self.ReloadDelay = nil
		return true
	end

	if self.ReloadDelay or CurTime() < self.ReloadWait then
		return false
	end

	if IsValid(wep) and self.dt.Status != FAS_STAT_HOLSTER_START then
		CT = CurTime()

		self:SetNextPrimaryFire(CT + (self.HolsterTime and self.HolsterTime * 2 or 0.75))
		self:SetNextSecondaryFire(CT + (self.HolsterTime and self.HolsterTime * 2 or 0.75))
		self.ReloadWait = CT + (self.HolsterTime and self.HolsterTime * 2 or 0.75)
		self.SprintDelay = CT + (self.HolsterTime and self.HolsterTime * 2 or 0.75)

		self.ChosenWeapon = wep:GetClass()

		if self.dt.Status != FAS_STAT_HOLSTER_END then
			timer.Simple((self.HolsterTime and self.HolsterTime or 0.45), function()
				if IsValid(self) and IsValid(self.Owner) and self.Owner:Alive() then
					self.dt.Status = FAS_STAT_HOLSTER_END
					self.dt.Bipod = false
					self.Owner:ConCommand("use " .. self.ChosenWeapon)
					//RunConsoleCommand("use", self.ChosenWeapon)
					//if SERVER then
					//	self.Owner:SelectWeapon(self.ChosenWeapon)
					//end
				end
			end)
		end

		self.dt.Status = FAS_STAT_HOLSTER_START
		self:PlayHolsterAnim()
	end

	//self:EmitSound("Generic_Cloth", 70, 100)

	if CLIENT then
		self.CurSoundTable = nil
		self.CurSoundEntry = nil
		self.SoundTime = nil
		self.SoundSpeed = 1
	end

	if SERVER and SP then
		SendUserMessage("FAS2_ENDSOUNDS", self.Owner)
	end

	self:EmitSound("weapons/weapon_holster" .. math.random(1, 3) .. ".wav", 50, 100)
	return false
end

local mod, cr, tr, aim

local td = {}

function SWEP:PlayFireAnim(mag)
	if self.dt.Status == FAS_STAT_ADS then
		if mag == 1 and (self.Anims.Fire_Aiming_Last or self.Anims.Fire_Bipod_Aiming_Last) then
			if self.dt.Bipod then
				FAS2_PlayAnim(self, self.Anims.Fire_Bipod_Aiming_Last and self.Anims.Fire_Bipod_Aiming_Last or self.Anims.Fire_Bipod_Last)
			else
				FAS2_PlayAnim(self, self.Anims.Fire_Aiming_Last and self.Anims.Fire_Aiming_Last or self.Anims.Fire_Last)
			end
		else
			if self.dt.Bipod then
				FAS2_PlayAnim(self, self.Anims.Fire_Bipod_Aiming and self.Anims.Fire_Bipod_Aiming or self.Anims.Fire_Bipod)
			else
				FAS2_PlayAnim(self, self.Anims.Fire_Aiming and self.Anims.Fire_Aiming or self.Anims.Fire)
			end
		end
	else
		if mag == 1 and (self.Anims.Fire_Last or self.Anims.Fire_Bipod_Last) then
			if self.dt.Bipod then
				FAS2_PlayAnim(self, self.Anims.Fire_Bipod_Last)
			else
				FAS2_PlayAnim(self, self.Anims.Fire_Last)
			end
		else
			if self.dt.Bipod then
				FAS2_PlayAnim(self, self.Anims.Fire_Bipod)
			else
				FAS2_PlayAnim(self, self.Anims.Fire)
			end
		end
	end
end

local ef

-- ============================================================
-- RECOIL BRAIN: Pure math, deterministic, zero visual coupling
-- Three-layer: this is Layer 1. cl_hud reads. sh_bullet consumes.
-- ============================================================
local _sprayAng = Angle(0, 0, 0)
local _projAng  = Angle(0, 0, 0)
local _sin      = math.sin
local _clamp    = math.Clamp
local _abs      = math.abs
local _max      = math.max
local _tan      = math.tan
local _rad      = math.rad

-- Pattern is stance-agnostic now. The old code scaled the pattern down in
-- ADS (p*0.75, y*0.50) which made bullets land at a DIFFERENT absolute
-- position than the same shot would land in hipfire — exactly the
-- two-cluster bug when toggling stance mid-spray.
--
-- ADS still feels tighter than hip via:
--   * `liftMode=1.0` in sh_bullet (camera fully tracks the pattern, so the
--     iron sights stay glued to where rounds land)
--   * the cone code (smaller random spread)
--   * the movement-bias multiplier (rifle planted = less drift)
--
-- The `stance` parameter is kept for backward compatibility but no longer
-- changes the per-shot output.
function SWEP:GetSprayOffset(index, stance)
	local cls = self.Class or self:GetClass()
	local pat = FAS2_SprayPatterns and FAS2_SprayPatterns[cls] or self.SprayPattern
	if not pat then return 0, 0 end

	local patLen = #pat
	if patLen < 1 then return 0, 0 end
	index = _clamp(index, 1, patLen)

	local entry = pat[index]

	local scale = FAS2_RecoilScale and FAS2_RecoilScale[cls] or self.RecoilScale or 1.0
	local crouchMod = self.Owner:Crouching() and 0.74 or 1
	local bipodMod = self.dt.Bipod and 0.25 or 1
	-- Keep the deterministic pattern itself invariant between hipfire and ADS.
	-- Movement/ADS penalties are applied as cone and movement bias elsewhere;
	-- scaling this value made mid-spray aim toggles split into two beams.
	local combined = scale * crouchMod * bipodMod

	return entry[1] * combined, entry[2] * combined
end

-- Predictable movement lean: when the player is strafing, the muzzle
-- lags behind the body, so bullets land on the OPPOSITE side of the
-- strafe direction. We expose this as a deterministic per-shot offset
-- (in degrees) that's added to BOTH the bullet direction AND the
-- follow-recoil dot — so movement shifts the dot somewhere predictable
-- instead of just randomizing the shot. ADS plants the rifle in the
-- shoulder, so the bias is dampened.
local _MOVE_RIGHT = Vector(0, 0, 0)
local _MOVE_FWD   = Vector(0, 0, 0)
function SWEP:GetMovementBias(stance)
	local owner = self.Owner
	if not IsValid(owner) then return 0, 0 end

	local vel = owner:GetVelocity()
	local speed2D = vel:Length2D()
	if speed2D < 6 then return 0, 0 end -- counter-strafe / still: zero

	local ea = owner:EyeAngles()
	local right = ea:Right()
	_MOVE_RIGHT.x, _MOVE_RIGHT.y, _MOVE_RIGHT.z = right.x, right.y, 0
	local rl = _MOVE_RIGHT:Length()
	if rl > 0.0001 then _MOVE_RIGHT:Mul(1 / rl) end

	local fwd = ea:Forward()
	_MOVE_FWD.x, _MOVE_FWD.y, _MOVE_FWD.z = fwd.x, fwd.y, 0
	local fl = _MOVE_FWD:Length()
	if fl > 0.0001 then _MOVE_FWD:Mul(1 / fl) end

	local strafe = vel:Dot(_MOVE_RIGHT) / 220 -- -1..+1 at run speed
	local fwdAmt = vel:Dot(_MOVE_FWD)   / 220

	-- Hipfire: full drift. ADS: rifle is planted, ~1/3 the drift.
	-- Blend continuously through the transition so the dot doesn't lurch.
	local adsFrac = type(stance) == "number" and stance or (stance and 1 or 0)
	local mult = 1.4 + (0.5 - 1.4) * adsFrac

	-- Source yaw convention: positive yaw = look LEFT. Strafing right
	-- (positive strafe) lags the barrel right of body → bullets land
	-- LEFT of aim → add positive yaw to bullet direction.
	local biasY = _clamp(strafe, -1.2, 1.2) * mult
	-- Forward run: very slight vertical bounce. Source pitch positive =
	-- look DOWN. Running forward jiggles aim slightly down.
	local biasP = _clamp(fwdAmt, -1.2, 1.2) * 0.3 * mult

	return biasP, biasY
end

-- ============================================================
-- ADS FRACTION (shared, time-eased)
-- Single source of truth for "how aimed-in are we right now."
-- Both client and server compute the same value at the same CurTime
-- because `dt.Status` is networked, so prediction stays in sync.
-- Replaces the binary `dt.Status == FAS_STAT_ADS` checks scattered
-- across the dot, camera, lift, kick and viewbob — they each blend
-- through this so the player can ADS mid-spray without a visible pop.
-- ============================================================
-- Effective spray reset window: weapon's `SprayResetTime` (typically 0.35s
-- or whatever the pattern editor stored for this class) scaled by the
-- replicated `fas2_spray_reset_mul` convar. All hot-path sites (AdvanceSpray,
-- Think, dot smoothing, isSpraying checks) read through this so changing
-- the convar takes effect immediately for every weapon, no per-class edit.
function SWEP:GetEffectiveSprayResetTime()
	local base = self.SprayResetTime or 0.35
	local cv = GetConVar("fas2_spray_reset_mul")
	local mul = cv and cv:GetFloat() or 1
	if mul <= 0 then mul = 1 end
	return base * mul
end

function SWEP:GetAdsFrac()
	local now = CurTime()
	local nowADS = self.dt and self.dt.Status == FAS_STAT_ADS or false

	if self._adsLastStatus ~= nowADS then
		-- Snapshot whatever frac we were at — handles flip-flop mid-ease
		-- by easing OUT from the in-progress value rather than restarting
		-- from the opposite extreme (which would itself be a visible pop).
		self._adsFromFrac = self._adsLastFrac or (nowADS and 0 or 1)
		self._adsTransitionStart = now
		self._adsLastStatus = nowADS
	end

	local elapsed = now - (self._adsTransitionStart or now)
	local dur = self.AdsTransitionTime or 0.18
	local t = elapsed / dur
	if t < 0 then t = 0 elseif t > 1 then t = 1 end
	local eased = t * t * (3 - 2 * t) -- smoothstep
	local target = nowADS and 1 or 0
	local from = self._adsFromFrac or 0
	local frac = from + (target - from) * eased
	self._adsLastFrac = frac
	return frac
end

-- ============================================================
-- ADS AIM-SNAP
-- When hipfire transitions into ADS mid-spray, the follow-recoil dot
-- is the player's true aim point (bullets land there). The iron sights
-- would naively replace the dot with screen center, jerking the player's
-- effective aim. Instead we capture the dot offset at the moment ADS
-- begins and rotate EyeAngles toward it as the transition completes,
-- so the iron sights physically pan into where the player was already
-- shooting. Bullets land in the same world position the whole way —
-- GetSprayDirection subtracts the snap from the per-shot offset so the
-- view rotation never drags rounds with it.
-- ============================================================
function SWEP:UpdateAdsAimSnap()
	do
	-- Compatibility shim only. Physical EyeAngles correction felt jittery with
	-- wide CS2-style patterns, so active ADS alignment is visual-only in
	-- cl_calcview.lua. Keep these zeroed so bullet prediction never subtracts
	-- a stale physical snap.
	self._adsSnapTargetP = 0
	self._adsSnapTargetY = 0
	self._adsSnapAppliedP = 0
	self._adsSnapAppliedY = 0
	self._adsSnapViewDeltaP = 0
	self._adsSnapViewDeltaY = 0
	self._adsSnapLastFrac = self.GetAdsFrac and self:GetAdsFrac() or 0
	return
	end

	if not IsValid(self.Owner) or not self.Owner:IsPlayer() then return end
	-- Only the bullet-firing player should rotate their own view. On client
	-- that's LocalPlayer; on server it's every owner of an active SWEP.
	if CLIENT and self.Owner ~= LocalPlayer() then return end

	local cv = GetConVar("fas2_ads_aim_snap")
	local snapScale = cv and cv:GetFloat() or 1
	if snapScale <= 0 then
		self._adsSnapTargetP, self._adsSnapTargetY = 0, 0
		self._adsSnapAppliedP, self._adsSnapAppliedY = 0, 0
		self._adsSnapLastFrac = self:GetAdsFrac()
		return
	end

	local frac     = self:GetAdsFrac()
	local lastFrac = self._adsSnapLastFrac or 0

	-- Crossing from full hipfire into the start of ADS: snapshot the
	-- upcoming bullet offset so the snap target reflects where the NEXT
	-- round will land, matching the follow-recoil dot instead of the
	-- already-fired round.
	-- Re-captures during a mid-transition flip-flop would chase the dot,
	-- which feels like the camera is wandering — so we only re-snapshot
	-- on a clean 0 → >0 edge.
	if lastFrac < 0.001 and frac >= 0.001 then
		local idx = self.PatternIndex or 0
		if idx >= 1 then
			local resetTime = self.GetEffectiveSprayResetTime and self:GetEffectiveSprayResetTime() or (self.SprayResetTime or 0.35)
			local willReset = CurTime() - (self.LastFireTime or 0) > resetTime
			local snapIdx = willReset and 1 or (idx + 1)
			local pP, pY = self:GetSprayOffset(snapIdx, 1)
			local biasP, biasY = self:GetMovementBias(1)
			self._adsSnapTargetP = (pP - (self._sprayLiftP or 0) + biasP) * snapScale
			self._adsSnapTargetY = (pY - (self._sprayLiftY or 0) + biasY) * snapScale
		else
			self._adsSnapTargetP = 0
			self._adsSnapTargetY = 0
		end
		self._adsSnapAppliedP = 0
		self._adsSnapAppliedY = 0
	end

	-- Apply rotation proportional to the frac delta. Going up (ADSing in)
	-- adds rotation; going back down (releasing) subtracts the same amount,
	-- so toggling ADS quickly without firing leaves the camera where it
	-- started — no permanent drift from incomplete transitions.
	-- The final correction follows a smootherstep curve so the tiny
	-- SetEyeAngles increments are gentler during ADS-in/out.
	local smoothAmount = _clamp(self.AdsAimSnapSmoothing or 1, 0, 1)
	local softFrac = frac * frac * frac * (frac * (frac * 6 - 15) + 10)
	local snapFrac = frac + (softFrac - frac) * smoothAmount
	local tP = self._adsSnapTargetP or 0
	local tY = self._adsSnapTargetY or 0
	local desiredP = tP * snapFrac
	local desiredY = tY * snapFrac
	local appliedP = self._adsSnapAppliedP or 0
	local appliedY = self._adsSnapAppliedY or 0
	local rotP = desiredP - appliedP
	local rotY = desiredY - appliedY
	if (tP ~= 0 or tY ~= 0 or appliedP ~= 0 or appliedY ~= 0) and (math.abs(rotP) > 0.0001 or math.abs(rotY) > 0.0001) then
		local ea = self.Owner:EyeAngles()
		ea.p = math.Clamp(ea.p + rotP, -89, 89)
		ea.y = ea.y + rotY
		self.Owner:SetEyeAngles(ea)

		self._adsSnapAppliedP = (self._adsSnapAppliedP or 0) + rotP
		self._adsSnapAppliedY = (self._adsSnapAppliedY or 0) + rotY

		if CLIENT and self.Owner == LocalPlayer() then
			self._adsSnapViewDeltaP = (self._adsSnapViewDeltaP or 0) + rotP
			self._adsSnapViewDeltaY = (self._adsSnapViewDeltaY or 0) + rotY
		end
	end

	-- Fully back to hipfire on both this and last frame: zero the trackers
	-- so a fresh ADS-in starts with a clean target snapshot.
	if frac < 0.001 and lastFrac < 0.001 and math.abs(self._adsSnapAppliedP or 0) < 0.001 and math.abs(self._adsSnapAppliedY or 0) < 0.001 then
		self._adsSnapTargetP = 0
		self._adsSnapTargetY = 0
		self._adsSnapAppliedP = 0
		self._adsSnapAppliedY = 0
	end

	self._adsSnapLastFrac = frac
end

function SWEP:GetSprayDirection()
	local idx = self.PatternIndex or 0
	if idx < 1 then return self.Owner:EyeAngles():Forward() end

	local adsFrac = self:GetAdsFrac()
	local pP, pY = self:GetSprayOffset(idx, adsFrac)
	local biasP, biasY = self:GetMovementBias(adsFrac)

	-- Subtract two cumulative camera rotations so bullets stay anchored to
	-- the SAME world-space point regardless of stance or transition state:
	--
	--   * _sprayLiftP/Y — the SetEyeAngles lift sh_bullet has pushed for
	--     each shot in this spray (CS-style permanent recoil).
	--   * _adsSnapAppliedP/Y — the additional rotation UpdateAdsAimSnap
	--     has eased in to bring iron sights to the dot during ADS-in.
	--
	-- Invariant:  bullet_aim_absolute  ==  orig_aim + pattern[idx] + bias
	-- regardless of how the camera has been rotated underneath the player.
	local liftedP = (self._sprayLiftP or 0) + (self._adsSnapAppliedP or 0)
	local liftedY = (self._sprayLiftY or 0) + (self._adsSnapAppliedY or 0)

	local ea = self.Owner:EyeAngles()
	_sprayAng.p = ea.p + (pP - liftedP) + biasP
	_sprayAng.y = ea.y + (pY - liftedY) + biasY
	_sprayAng.r = 0
	return _sprayAng:Forward()
end

local _dotTrace = {}
local MASK_SHOT = MASK_SHOT
local _GRAVITY_VEC = Vector(0, 0, -600)
local _SIM_DT = 0.035
local _SIM_STEPS = 14
local _ballisticAng = Angle(0, 0, 0)
local _math_atan2 = math.atan2
local _math_deg = math.deg

local function CalcBulletArc(dist, muzzleVel, gravity)
	local travelTime = dist / muzzleVel
	return 0.5 * gravity * travelTime * travelTime
end

local function CalcZeroedBulletOffset(dist, muzzleVel, gravity, zeroDist)
	local drop = CalcBulletArc(dist, muzzleVel, gravity)
	if not zeroDist or zeroDist <= 0 then
		return drop
	end

	local zeroLift = CalcBulletArc(zeroDist, muzzleVel, gravity) * (dist / zeroDist)
	return drop - zeroLift
end

function SWEP:GetBallisticTuning()
	local gravity = self.BallisticGravity or 150
	local zeroDist = self.BallisticZeroDistance or 3937

	if FAS2_Ballistics then
		local cls = self.Class or self:GetClass()
		local tuning = FAS2_Ballistics[cls]
		if tuning then
			gravity = tuning.gravity or gravity
			zeroDist = tuning.zero or zeroDist
		end
	end

	local muzzleVel = self.MuzzleVelocity or 18000

	-- Ammo profile (hv / volatile / standard) tweaks muzzle velocity so that
	-- HV rounds actually fly flatter and reach farther, and volatile rounds
	-- (incendiary/explosive) sit slower in the air. Sweet-spot range derives
	-- from the same multiplier in GetEffectiveSweetSpotRange below, so the
	-- two stay in sync without per-system tuning.
	if FAS2PatternEditor and FAS2PatternEditor.GetAmmoProfile then
		local profile = FAS2PatternEditor.GetAmmoProfile(self)
		local m = tonumber(profile and profile.multiplier) or 1
		muzzleVel = muzzleVel * m
	end

	return muzzleVel, gravity, zeroDist
end

-- Resolve the weapon's "sweet spot" engagement range in source units.
-- Prefers the wall distance captured during pattern calibration (extended
-- or shortened by ammo profile), and falls back to the static
-- SWEP.EffectiveRange when no calibrated pattern exists.
function SWEP:GetEffectiveSweetSpotRange()
	if FAS2PatternEditor and FAS2PatternEditor.GetSweetSpotData then
		local data = FAS2PatternEditor.GetSweetSpotData(self)
		if data and tonumber(data.sweetSpotUnits) and data.sweetSpotUnits > 0 then
			return data.sweetSpotUnits
		end
	end

	local fallback = tonumber(self.EffectiveRange) or 3000
	if FAS2PatternEditor and FAS2PatternEditor.GetAmmoProfile then
		local profile = FAS2PatternEditor.GetAmmoProfile(self)
		fallback = fallback * (tonumber(profile and profile.multiplier) or 1)
	end
	return fallback
end

-- Stance & movement accuracy model.
-- The recorded spray pattern is the BEST-CASE outcome: standing still, on the
-- ground, ideally ADS, and not having just spawned-jumped. Anything that
-- deviates from that adds cone on top of the pattern. Counter-strafing in CS
-- (tapping the opposite move key so the velocity drops to ~0) snaps accuracy
-- back to full instantly, because this function reads live velocity each shot.
--
-- Returns a table:
--   coneMult         multiplier on the late-spray cone (CurCone units)
--   movementCone     additive cone in CurCone units (applies even on shot 1)
--   patternMult      extra amplitude scaler on the pattern itself
--   speed            current 2D speed (units/s) for HUD/debug
--   status           string label for HUD: STILL / WALK / RUN / SPRINT / AIR
function SWEP:GetStanceAccuracy()
	local owner = self.Owner
	if not IsValid(owner) then
		return { coneMult = 1, movementCone = 0, patternMult = 1, speed = 0, status = "STILL" }
	end

	local speed     = owner:GetVelocity():Length2D()
	local crouching = owner:Crouching()
	local onGround  = owner:IsOnGround()
	local isADS     = self.dt and self.dt.Status == FAS_STAT_ADS
	local bipod     = self.dt and self.dt.Bipod

	-- Source-engine ballpark thresholds (units/s):
	--   <6     = effectively zero (perfect counter-strafe / standing still)
	--   <185   = quiet walk / crouch ladder
	--   <255   = normal run / timed movement tap
	--   >255   = boosted sprint
	local STILL = 6
	local WALK  = 185
	local RUN   = 255

	local coneMult, movementCone, patternMult = 1, 0, 1
	local status

	if not onGround then
		coneMult     = 4.0
		movementCone = 0.6   -- ~2.4 deg of base spread mid-air
		patternMult  = 1.6
		status       = "AIR"
	elseif speed < STILL then
		status = crouching and "STILL_CROUCH" or "STILL"
	elseif speed < WALK then
		local t = (speed - STILL) / (WALK - STILL)
		coneMult     = 1 + t * 0.8
		movementCone = t * 0.08          -- ~0.3 deg max shift-walk
		patternMult  = 1 + t * 0.10
		status       = "WALK"
	elseif speed < RUN then
		local t = (speed - WALK) / (RUN - WALK)
		coneMult     = 1.8 + t * 1.0
		movementCone = 0.08 + t * 0.27   -- up to ~1.4 deg of run-shoot
		patternMult  = 1.10 + t * 0.25
		status       = "RUN"
	else
		local t = math.Clamp((speed - RUN) / 120, 0, 1)
		coneMult     = 2.8 + t * 1.5
		movementCone = 0.35 + t * 0.4    -- ~3 deg sprint-shoot
		patternMult  = 1.35 + t * 0.4
		status       = "SPRINT"
	end

	-- Crouched & grounded shrinks both extra cones (CS-style crouch bonus).
	if crouching and onGround then
		coneMult     = coneMult * 0.62
		movementCone = movementCone * 0.62
		patternMult  = 1 + (patternMult - 1) * 0.82
	end

	-- ADS while grounded gives a stability bonus (you've planted, sights up).
	-- ADS does NOT save you from full-sprint shooting.
	if isADS and onGround and status ~= "SPRINT" then
		coneMult     = coneMult * 0.55
		movementCone = movementCone * 0.55
		patternMult  = 1 + (patternMult - 1) * 0.7
	end

	-- Bipod deployed = locked in, basically removes movement penalty.
	if bipod then
		coneMult     = 1
		movementCone = 0
		patternMult  = 1
	end

	return {
		coneMult     = coneMult,
		movementCone = movementCone,
		patternMult  = patternMult,
		speed        = speed,
		status       = status,
	}
end

function SWEP:GetBallisticOffsetAtDistance(dist)
	local muzzleVel, gravity, zeroDist = self:GetBallisticTuning()
	return CalcZeroedBulletOffset(dist, muzzleVel, gravity, zeroDist)
end

function SWEP:GetZeroedBulletDirection(dir)
	if self.BulletDrop == false then
		return dir
	end

	local muzzleVel, gravity, zeroDist = self:GetBallisticTuning()
	if not zeroDist or zeroDist <= 0 then
		return dir
	end

	local zeroDrop = CalcBulletArc(zeroDist, muzzleVel, gravity)
	_ballisticAng = dir:Angle()
	_ballisticAng.p = _ballisticAng.p - _math_deg(_math_atan2(zeroDrop, zeroDist))
	_ballisticAng.r = 0
	return _ballisticAng:Forward()
end

function SWEP:GetNextBulletScreenPos()
	local idx = self.PatternIndex or 0
	local cx, cy = ScrW() * 0.5, ScrH() * 0.5

	-- Predict the NEXT shot's pattern index the same way AdvanceSpray will:
	-- if the spray reset window has elapsed, the next shot is index 1 and
	-- the lift accumulator will have been zeroed by then — mirror that here
	-- so the predicted dot lands where the round actually will.
	local t = CurTime()
	local resetTime = self:GetEffectiveSprayResetTime()
	local willReset = t - (self.LastFireTime or 0) > resetTime
	local nextIdx = willReset and 1 or (idx + 1)

	local adsFrac = self:GetAdsFrac()
	local nextP, nextY = self:GetSprayOffset(nextIdx, adsFrac)
	local biasP, biasY = self:GetMovementBias(adsFrac)

	-- Mirror GetSprayDirection's accumulator subtraction (lift + aim-snap)
	-- so the predicted dot lands where rounds will actually go even mid
	-- ADS transition — without this, the dot would visibly drift as the
	-- camera rotates underneath it during the aim-snap phase.
	local liftedP = willReset and 0 or ((self._sprayLiftP or 0) + (self._adsSnapAppliedP or 0))
	local liftedY = willReset and 0 or ((self._sprayLiftY or 0) + (self._adsSnapAppliedY or 0))

	local ea = self.Owner:EyeAngles()
	_sprayAng.p = ea.p + (nextP - liftedP) + biasP
	_sprayAng.y = ea.y + (nextY - liftedY) + biasY
	_sprayAng.r = 0
	local dir = _sprayAng:Forward()

	local sp = self.Owner:GetShootPos()
	local muzzleVel, gravity, zeroDist = self:GetBallisticTuning()
	local hasDrop = self.BulletDrop ~= false

	_dotTrace.filter = self.Owner
	_dotTrace.mask   = MASK_SHOT
	_dotTrace.start  = sp
	_dotTrace.endpos = sp + dir * 32768

	local pre = util.TraceLine(_dotTrace)
	local hitDist = pre.HitPos:Distance(sp)

	if hasDrop and hitDist > 256 then
		local drop = CalcZeroedBulletOffset(hitDist, muzzleVel, gravity, zeroDist)
		_ballisticAng = dir:Angle()
		_ballisticAng.p = _ballisticAng.p + _math_deg(_math_atan2(drop, hitDist))
		_ballisticAng.r = 0
		local fireDir = _ballisticAng:Forward()

		_dotTrace.start  = sp
		_dotTrace.endpos = sp + fireDir * 32768
		local tr = util.TraceLine(_dotTrace)
		local scr = tr.HitPos:ToScreen()
		if scr.visible then return scr.x, scr.y end
		return cx, cy
	end

	local scr = pre.HitPos:ToScreen()
	if scr.visible then return scr.x, scr.y end
	return cx, cy
end

function SWEP:EnsureSprayData()
	if self._sprayDataLoaded then return end

	local cls = self.Class or self:GetClass()
	local loaded = false

	if not self.SprayPattern and FAS2_SprayPatterns and FAS2_SprayPatterns[cls] then
		self.SprayPattern = FAS2_SprayPatterns[cls]
		print("[FAS2 FALLBACK] Loaded spray pattern for " .. cls .. " (" .. #self.SprayPattern .. " entries)")
		loaded = true
	end

	if FAS2_RecoilScale and FAS2_RecoilScale[cls] then
		self.RecoilScale = FAS2_RecoilScale[cls]
		if loaded then
			print("[FAS2 FALLBACK] Loaded RecoilScale for " .. cls .. " = " .. self.RecoilScale)
		end
	end

	if FAS2_MuzzleVelocity and FAS2_MuzzleVelocity[cls] then
		self.MuzzleVelocity = FAS2_MuzzleVelocity[cls]
	end

	if FAS2_Ballistics and FAS2_Ballistics[cls] then
		local tuning = FAS2_Ballistics[cls]
		self.BallisticGravity = tuning.gravity or self.BallisticGravity
		self.BallisticZeroDistance = tuning.zero or self.BallisticZeroDistance
	end

	if FAS2_SprayResetTime and FAS2_SprayResetTime[cls] then
		self.SprayResetTime = FAS2_SprayResetTime[cls]
	end

	self._sprayDataLoaded = true
end

function SWEP:AdvanceSpray()
	self:EnsureSprayData()

	local t = CurTime()
	local resetTime = self:GetEffectiveSprayResetTime()

	if t - (self.LastFireTime or 0) > resetTime then
		self.PatternIndex = 0
		-- Spray window expired: zero the lift accumulator too so the next
		-- shot's offset math starts from a clean slate (matches the engine
		-- having "forgotten" the old camera lift for prediction purposes).
		self._sprayLiftP = 0
		self._sprayLiftY = 0
	end

	self.PatternIndex = (self.PatternIndex or 0) + 1
	self.LastFireTime = t
end

-- ============================================================
-- MOVEMENT ACCURACY: CS2-grade with counter-strafe detection
-- Returns multiplier: 0.75 (best) to 3.5+ (worst)
-- CS2 pros who counter-strafe get rewarded here.
-- ============================================================
-- Returns a single scalar (1.0 = perfect, higher = worse) for the HUD dot
-- color gradient. Single source of truth: derives from GetStanceAccuracy so
-- the HUD color cannot drift from actual bullet cone behavior.
function SWEP:GetMovementAccuracy()
	if not self.GetStanceAccuracy then return 1.0 end
	local s = self:GetStanceAccuracy()
	if not s then return 1.0 end
	-- coneMult is 1.0 standing still and scales up with movement; movementCone
	-- is the additive cone (deg/4) applied even on shot 1. Sum them with a
	-- modest weighting so the HUD gradient hits its yellow/red bands at the
	-- same speeds the bullets actually punish.
	return (s.coneMult or 1) + (s.movementCone or 0) * 2.5
end

function SWEP:AimRecoil(mul)
end

function SWEP:HipRecoil(mul)
	if not IsValid(self.Owner) then return end
	local idx = self.PatternIndex or 0
	if idx < 1 then return end

	local pP, pY = self:GetSprayOffset(idx, false)
	local prevP, prevY = 0, 0
	if idx > 1 then
		prevP, prevY = self:GetSprayOffset(idx - 1, false)
	end
	local dP = pP - prevP
	local dY = pY - prevY

	if CLIENT then
		if not self._punchVel then self._punchVel = Angle(0,0,0) end
		self._punchVel.p = self._punchVel.p + dP * 0.12
		self._punchVel.y = self._punchVel.y + dY * 0.08
		self._punchVel.r = self._punchVel.r + dY * 0.03

		self._camAccP = (self._camAccP or 0) + dP * 0.65
		self._camAccY = (self._camAccY or 0) + dY * 0.65
	end
end

function SWEP:PrimaryAttack()
	if self.FireMode == "safe" then
		if IsFirstTimePredicted() then
			self:CycleFiremodes()
		end

		return
	end

	if IsFirstTimePredicted() then
		if self.BurstAmount > 0 and self.dt.Shots >= self.BurstAmount then
			return
		end

		if self.ReloadState != 0 then
			self.ReloadState = 3
			return
		end

		if self.dt.Status == FAS_STAT_CUSTOMIZE then
			return
		end

		if self.Cooking or self.FuseTime then
			return
		end

		if self.Owner:KeyDown(IN_USE) then
			if self:CanThrowGrenade() then
				self:InitialiseGrenadeThrow()
				return
			end
		end

		if self.dt.Status == FAS_STAT_SPRINT or self.dt.Status == FAS_STAT_QUICKGRENADE then
			return
		end

		td.start = self.Owner:GetShootPos()
		td.endpos = td.start + self.Owner:GetAimVector() * 30
		td.filter = self.Owner

		tr = util.TraceLine(td)

		if tr.Hit then
			return
		end

		mag = self:Clip1()
		CT = CurTime()

		if mag <= 0 or self.Owner:WaterLevel() >= 3 then
			self:EmitSound(self.EmptySound, 60, 100)
			self:SetNextPrimaryFire(CT + 0.2)
			//self:EmitSound("FAS2_DRYFIRE", 70, 100)
			return
		end

		if self.CockAfterShot and not self.Cocked then
			if SERVER then
				if SP then
					SendUserMessage("FAS2_COCKREMIND", self.Owner) -- wow okay
				end
			else
				self.CockRemindTime = CurTime() + 1
			end

			return
		end

		self:FireBullet()

		if CLIENT then
			self:CreateMuzzle()

			if self.Shell and self.CreateShell then
				self:CreateShell()
			end
		end

		ef = EffectData()
		ef:SetEntity(self)
		util.Effect("fas2_ef_muzzleflash", ef)

		mod = self.Owner:Crouching() and 0.75 or 1

		self:PlayFireAnim(mag)

		if self.dt.Status == FAS_STAT_ADS then
			if self.BurstAmount > 0 then
				if self.DelayedBurstRecoil then
					if self.dt.Shots == self.ShotToDelayUntil then
						self:AimRecoil(self.BurstRecoilMod)
					end
				else
					self:AimRecoil(self.BurstRecoilMod)
				end
			else
				self:AimRecoil()
			end
		else
			if self.BurstAmount > 0 then
				if self.DelayedBurstRecoil then
					if self.dt.Shots == self.ShotToDelayUntil then
						self:HipRecoil(self.BurstRecoilMod)
					end
				else
					self:HipRecoil(self.BurstRecoilMod)
				end
			else
				self:HipRecoil()
			end
		end

		self.SpreadWait = CT + self.SpreadCooldown

		if self.BurstAmount > 0 then
			self.AddSpread = math.Clamp(self.AddSpread + self.SpreadPerShot * mod * 0.5, 0, self.MaxSpreadInc)
			self.AddSpreadSpeed = math.Clamp(self.AddSpreadSpeed - 0.2 * mod * 0.5, 0, 1)
		else
			self.AddSpread = math.Clamp(self.AddSpread + self.SpreadPerShot * mod, 0, self.MaxSpreadInc)
			self.AddSpreadSpeed = math.Clamp(self.AddSpreadSpeed - 0.2 * mod, 0, 1)
		end

		if self.CockAfterShot then
			self.Cocked = false
		end

		if SERVER and SP then
			SendUserMessage("FAS2SPREAD", self.Owner)
		end

		if CLIENT then
			self.CheckTime = 0
		end

		if self.dt.Suppressed then
			self:EmitSound(self.FireSound_Suppressed, 75, 100)
		else
			self:EmitSound(self.FireSound, 105, 100)
		end

		self.Owner:SetAnimation(PLAYER_ATTACK1)

		self.ReloadWait = CT + 0.3
	end

	if self.BurstAmount > 0 then
		self.dt.Shots = self.dt.Shots + 1
		self:SetNextPrimaryFire(CT + self.FireDelay * self.BurstFireDelayMod)
	else
		self:SetNextPrimaryFire(CT + self.FireDelay)
	end

	self:TakePrimaryAmmo(1)

	//self:SetNextSecondaryFire(CT + 0.1)

	return
end

function SWEP:SecondaryAttack()
	if self.FireMode == "safe" then
		return
	end

	if self.ReloadState != 0 then
		return
	end

	if self.Owner:KeyDown(IN_USE) then
		return
	end

	if self.dt.Status == FAS_STAT_SPRINT or self.dt.Status == FAS_STAT_CUSTOMIZE or self.dt.Status == FAS_STAT_QUICKGRENADE or self.dt.Status == FAS_STAT_ADS then
		return
	end

	self.dt.Status = FAS_STAT_ADS
	self:EmitSound(table.Random(self.AimSounds), 50, 100)

	self:SetNextPrimaryFire(CT + 0.1)
	self:SetNextSecondaryFire(CT + 0.1)
	self.ReloadWait = CT + 0.3

	return
end

function SWEP:Equip()
	if self.ExtraMags then
		if gamemode.Get("sandbox") then
			self.Owner:GiveAmmo(self.ExtraMags * self.Primary.ClipSize, self.Primary.Ammo)
		end
	end

	if self.AttOnPickUp then
		for k, v in pairs(self.AttOnPickUp) do
			self.Owner:FAS2_PickUpAttachment(v, true)
		end
	end
end

function SWEP:UnloadWeapon()
	mag = self:Clip1()
	self:SetClip1(0)

	if CLIENT then
		self.CheckTime = CT + 3
	else
		self.Owner:GiveAmmo(mag, self.Primary.Ammo)
	end
end

function SWEP:CalculateSpread()
	aim = self.Owner:GetAimVector()

	if not self.Owner.LastView then
		self.Owner.LastView = aim
		self.Owner.ViewAff = 0
	else
		self.Owner.ViewAff = Lerp(0.25, self.Owner.ViewAff, (aim - self.Owner.LastView):Length() * 0.5)
		self.Owner.LastView = aim
	end

	local onGround = self.Owner:OnGround()

	if not self.WasOnGround and onGround then
		self.LandingPenalty = CT + 0.35
	end
	self.WasOnGround = onGround

	local landingAdd = 0
	if self.LandingPenalty and CT < self.LandingPenalty then
		landingAdd = 0.035 * ((self.LandingPenalty - CT) / 0.35)
	end

	local airAdd = 0
	if not onGround then
		airAdd = 0.05
	end

	cone = self.HipCone * (cr and 0.75 or 1) * (self.dt.Bipod and 0.3 or 1)

	if self.dt.Status == FAS_STAT_ADS then
		td.start = self.Owner:GetShootPos()
		td.endpos = td.start + aim * 30
		td.filter = self.Owner

		tr = util.TraceLine(td)

		if tr.Hit then
			self.dt.Status = FAS_STAT_IDLE
			self:SetNextPrimaryFire(CT + 0.2)
			self:SetNextSecondaryFire(CT + 0.2)
			self.ReloadWait = CT + 0.2
		else
			cone = self.AimCone
		end
	end

	local moveAcc = self:GetMovementAccuracy()
	local movePenalty = (moveAcc - 1) * 0.015

	self.CurCone = math.Clamp(cone + self.AddSpread * (self.dt.Bipod and 0.5 or 1) + movePenalty + (vel / 10000 * self.VelocitySensitivity) * (self.dt.Status == FAS_STAT_ADS and 0.25 or 1) + self.Owner.ViewAff + landingAdd + airAdd, 0, 0.09 + self.MaxSpreadInc)

	if CT > self.SpreadWait then
		local recoveryMul = 1 + (1 - math.Clamp(self.AddSpread / math.max(self.MaxSpreadInc, 0.01), 0, 1)) * 0.6
		self.AddSpread = math.Clamp(self.AddSpread - 0.006 * self.AddSpreadSpeed * recoveryMul, 0, self.MaxSpreadInc)
		self.AddSpreadSpeed = math.Clamp(self.AddSpreadSpeed + 0.06, 0, 1)
	end
end

local can

function SWEP:CanDeployBipod()
	vel = Length(GetVelocity(self.Owner))

	if vel == 0 and self.Owner:EyeAngles().p <= 45 then
		sp = self.Owner:GetShootPos()
		aim = self.Owner:GetAimVector()

		td.start = sp
		td.endpos = td.start + aim * 50
		td.filter = self.Owner

		tr = util.TraceLine(td)

		if not tr.Hit then
			td.start = sp
			td.endpos = td.start + Vector(aim.x, aim.y, -1) * 25
			td.filter = self.Owner
			td.mins = Vector(-8, -8, -1)
			td.maxs = Vector(8, 8, 1)

			tr = util.TraceHull(td)

			if tr.Hit and tr.HitPos.z + 10 < sp.z then -- make sure we have something to place the bipod on and we're not placing the bipod on something lower than our standing position
				ent = tr.Entity

				if not ent:IsPlayer() and not ent:IsNPC() then
					return true
				end
			end
		end
	end

	return false
end

function SWEP:PlayBipodDeployAnim()
	if self:Clip1() == 0 and self.Anims.Bipod_Deploy_Empty then
		FAS2_PlayAnim(self, self.Anims.Bipod_Deploy_Empty, 1)
	else
		FAS2_PlayAnim(self, self.Anims.Bipod_Deploy, 1)
	end
end

function SWEP:PlayBipodUnDeployAnim()
	if self:Clip1() == 0 and self.Anims.Bipod_UnDeploy_Empty then
		FAS2_PlayAnim(self, self.Anims.Bipod_UnDeploy_Empty, 1)
	else
		FAS2_PlayAnim(self, self.Anims.Bipod_UnDeploy, 1)
	end
end

function SWEP:Think()
	if self.ShotgunThink then
		self:ShotgunThink()
	end

	-- Eases iron sights onto the follow-recoil dot during ADS-in. Runs every
	-- tick on both client and server; the rotation is computed deterministically
	-- from CurTime + spray state so prediction matches without networking.
	if self.UpdateAdsAimSnap then self:UpdateAdsAimSnap() end

	cr = self.Owner:Crouching()
	CT, vel = CurTime(), Length(GetVelocity(self.Owner))

	if self.ReloadDelay and self.Owner:KeyDown(IN_ATTACK) and CT < self.ReloadDelay then
		if self:AbortReload() then return end
	end

	if self.ReloadDelay and CT >= self.ReloadDelay then
		mag, ammo = self:Clip1(), self.Owner:GetAmmoCount(self.Primary.Ammo)

		if SERVER then
			if not self.NoProficiency then
				if not self.Owner.FAS_FamiliarWeapons[self.Class] then
					if not self.Owner.FAS_FamiliarWeaponsProgress[self.Class] then
						self.Owner.FAS_FamiliarWeaponsProgress[self.Class] = 0
					end

					self.Owner.FAS_FamiliarWeaponsProgress[self.Class] = self.Owner.FAS_FamiliarWeaponsProgress[self.Class] + GetConVarNumber("fas2_profgain") * (mag == 0 and 1.5 or 1)

					if self.Owner.FAS_FamiliarWeaponsProgress[self.Class] >= 1 then
						self:FamiliariseWithWeapon()
					end
				end
			end
		end

		if self.ReloadAmount then
			if SERVER then
				self:SetClip1(math.Clamp(mag + self.ReloadAmount, 0, self.Primary.ClipSize))
				self.Owner:RemoveAmmo(self.ReloadAmount, self.Primary.Ammo)
			end
		else
			if mag > 0 then
				local need = math.max(self.Primary.ClipSize - mag, 0)
				if ammo >= need then
					if SERVER then
						self:SetClip1(math.Clamp(self.Primary.ClipSize, 0, self.Primary.ClipSize))
						self.Owner:RemoveAmmo(need, self.Primary.Ammo)
					end
				else
					if SERVER then
						self:SetClip1(math.Clamp(mag + ammo, 0, self.Primary.ClipSize))
						self.Owner:RemoveAmmo(ammo, self.Primary.Ammo)
					end
				end
			else
				if ammo >= self.Primary.ClipSize then
					if SERVER then
						self:SetClip1(math.Clamp(self.Primary.ClipSize, 0, self.Primary.ClipSize))
						self.Owner:RemoveAmmo(self.Primary.ClipSize, self.Primary.Ammo)
					end
				else
					if SERVER then
						self:SetClip1(math.Clamp(ammo, 0, self.Primary.ClipSize))
						self.Owner:RemoveAmmo(ammo, self.Primary.Ammo)
					end
				end
			end
		end

		self.ReloadDelay = nil
		self._fas2Reloading = false
		self._nextReloadAccept = CT + (self.ReloadRestartLockout or 0.22)
	end

	if (SP and SERVER) or not SP then -- if it's SP, then we run it only on the server (otherwise shit gets fucked); if it's MP we predict it
		if self.dt.Bipod or self.DeployAngle then
			if not self:CanDeployBipod() then
				self.dt.Bipod = false
				self.DeployAngle = nil

				if not self.ReloadDelay then
					if CT > self.BipodDelay then
						self:PlayBipodUnDeployAnim()
						self.BipodDelay = CT + self.BipodUndeployTime
						self:SetNextPrimaryFire(CT + self.BipodUndeployTime)
						self:SetNextSecondaryFire(CT + self.BipodUndeployTime)
						self.ReloadWait = CT + self.BipodUndeployTime
					else
						self.BipodUnDeployPost = true
					end
				else
					self.BipodUnDeployPost = true
				end
			end
		end

		if not self.ReloadDelay then
			if self.BipodUnDeployPost then
				if CT > self.BipodDelay then
					if not self:CanDeployBipod() then
						self:PlayBipodUnDeployAnim()
						self.BipodDelay = CT + self.BipodUndeployTime
						self:SetNextPrimaryFire(CT + self.BipodUndeployTime)
						self:SetNextSecondaryFire(CT + self.BipodUndeployTime)
						self.ReloadWait = CT + self.BipodUndeployTime
						self.BipodUnDeployPost = false
					else
						self.dt.Bipod = true

						if SP and SERVER then
							umsg.Start("FAS2_DEPLOYANGLE", self.Owner)
								umsg.Angle(self.Owner:EyeAngles())
							umsg.End()
						else
							self.DeployAngle = self.Owner:EyeAngles()
						end

						self.BipodUnDeployPost = false
					end
				end
			end

			if self.Owner:KeyPressed(IN_USE) then
				if CT > self.BipodDelay and CT > self.ReloadWait then
					if self.InstalledBipod then
						if self.dt.Bipod then
							self.dt.Bipod = false
							self.DeployAngle = nil

							self.BipodDelay = CT + self.BipodUndeployTime
							self:SetNextPrimaryFire(CT + self.BipodUndeployTime)
							self:SetNextSecondaryFire(CT + self.BipodUndeployTime)
							self.ReloadWait = CT + self.BipodUndeployTime
							self:PlayBipodUnDeployAnim()
						else
							self.dt.Bipod = self:CanDeployBipod()

							if self.dt.Bipod then
								self.BipodDelay = CT + self.BipodDeployTime
								self:SetNextPrimaryFire(CT + self.BipodDeployTime)
								self:SetNextSecondaryFire(CT + self.BipodDeployTime)
								self.ReloadWait = CT + self.BipodDeployTime

								if SP and SERVER then
									umsg.Start("FAS2_DEPLOYANGLE", self.Owner)
										umsg.Angle(self.Owner:EyeAngles())
									umsg.End()
								else
									self.DeployAngle = self.Owner:EyeAngles()
								end

								self:PlayBipodDeployAnim()
							end
						end
					end
				end
			end

			self.Secondary.Automatic = true

			if not self.Owner:KeyDown(IN_ATTACK2) then
				if self.dt.Status == FAS_STAT_ADS then
					self.dt.Status = FAS_STAT_IDLE
					self:SetNextSecondaryFire(CT + 0.1)
					self.ReloadWait = CT + 0.3
					self:EmitSound(table.Random(self.BackToHipSounds), 50, 100)
				end
			end
		end
	end

	if self.Owner:KeyDown(IN_USE) and self.Owner:KeyDown(IN_ATTACK2) then
		if SERVER and SP then
			SendUserMessage("FAS2_CHECKWEAPON", self.Owner)
		end

		if CLIENT then
			self.CheckTime = CT + 0.5
		end

		return
	end

	if self.dt.Status != FAS_STAT_HOLSTER_START and self.dt.Status != FAS_STAT_HOLSTER_END and self.dt.Status != FAS_STAT_QUICKGRENADE then
		if self.dt.Status == FAS_STAT_ADS then
			-- ADS movement is capped in FAS2_Move. Do not mutate the
			-- player's base speed here or aiming can leave them stuck slow.
		else
			if self.Owner:OnGround() then
				if self.Owner:KeyDown(IN_SPEED) and vel >= self.Owner:GetWalkSpeed() * 1.3 then
					if self.dt.Status != FAS_STAT_SPRINT then
						self.dt.Status = FAS_STAT_SPRINT
					end
				else
					if self.dt.Status == FAS_STAT_SPRINT then
						self.dt.Status = FAS_STAT_IDLE

						if CT > self.SprintDelay and not self.ReloadDelay then
							self:SetNextPrimaryFire(CT + 0.2)
							self:SetNextSecondaryFire(CT + 0.2)
						end
					end
				end
			else
				if self.dt.Status == FAS_STAT_SPRINT then
					self.dt.Status = FAS_STAT_IDLE

					if CT > self.SprintDelay and not self.ReloadDelay then
						self:SetNextPrimaryFire(CT + 0.2)
						self:SetNextSecondaryFire(CT + 0.2)
					end
				end
			end
		end
	end

	self:CalculateSpread()

	if not self.Owner:KeyDown(IN_ATTACK) then
		local resetTime = self:GetEffectiveSprayResetTime()
		if CT - (self.LastFireTime or 0) > resetTime then
			if self.PatternIndex and self.PatternIndex > 0 then
				self.PatternIndex = 0
				self._sprayLiftP = 0
				self._sprayLiftY = 0
			end
		end
	end

	if self.dt.Shots > 0 then
		if not self.Owner:KeyDown(IN_ATTACK) then
			self:SetNextPrimaryFire(CT + self.FireDelay * 2)
			self:SetNextSecondaryFire(CT + 0.1)
			self.ReloadWait = CT + self.FireDelay * 3
			self.dt.Shots = 0
		end
	end

	if self.CurSoundTable then
		t = self.CurSoundTable[self.CurSoundEntry]

		if CLIENT then
			if self.Wep:SequenceDuration() * self.Wep:GetCycle() >= t.time / self.SoundSpeed then
				self:EmitSound(t.sound, 70, 100)

				if self.CurSoundTable[self.CurSoundEntry + 1] then
					self.CurSoundEntry = self.CurSoundEntry + 1
				else
					self.CurSoundTable = nil
					self.CurSoundEntry = nil
					self.SoundTime = nil
				end
			end
		else
			if CT >= self.SoundTime + t.time / self.SoundSpeed then
				self:EmitSound(t.sound, 70, 100)

				if self.CurSoundTable[self.CurSoundEntry + 1] then
					self.CurSoundEntry = self.CurSoundEntry + 1
				else
					self.CurSoundTable = nil
					self.CurSoundEntry = nil
					self.SoundTime = nil
				end
			end
		end
	end

	if self.TimeToAdvance and CT > self.TimeToAdvance then
		if self.AdvanceStage == "draw" then
			self:DrawGrenade()
		elseif self.AdvanceStage == "prepare" then
			self:AdvanceGrenadeThrow()
		end
	end

	if self.Cooking then
		if self.FuseTime then
			if not self.Owner:KeyDown(IN_ATTACK) then
				if CT > self.TimeToThrow then
					self:ThrowGrenade()
				end
			else
				if CT > self.TimeToThrow then
					self.ThrowPower = math.Approach(self.ThrowPower, 1, FrameTime())
				end

				if SERVER then
					if CT >= self.FuseTime then
						self.Cooking = false
						self.FuseTime = nil
						util.BlastDamage(self.Owner, self.Owner, self:GetPos(), 384, 100)
						self.Owner:Kill()

						ef = EffectData()
						ef:SetOrigin(self.Owner:GetPos())
						ef:SetMagnitude(1)

						util.Effect("Explosion", ef)
					end
				end
			end
		end
	end

	for k, v in pairs(self.Events) do
		if CT > v.time then
			v.func()
			table.remove(self.Events, k)
		end
	end
end

if SERVER then
	function SWEP:FamiliariseWithWeapon()
		self.Owner.FAS_FamiliarWeapons = self.Owner.FAS_FamiliarWeapons and self.Owner.FAS_FamiliarWeapons or {}
		self.Owner.FAS_FamiliarWeapons[self.Class] = true

		umsg.Start("FAS2_FAMILIARISE", self.Owner)
			umsg.String(self.Class)
		umsg.End()
	end

	function SWEP:Suppress()
		if self.CantSuppress then
			return
		end

		self.dt.Suppressed = true

		SendUserMessage("FAS2_SUPPRESSMODEL", self.Owner)
	end

	function SWEP:UnSuppress()
		if self.CantSuppress then
			return
		end

		self.dt.Suppressed = true

		SendUserMessage("FAS2_UNSUPPRESSMODEL", self.Owner)
	end
end

function SWEP:CanThrowGrenade()
	if self.FireMode != "safe" then
		if self.Owner:HasWeapon("fas2_m67") then
			if self.Owner:GetAmmoCount("M67 Grenades") > 0 then
				return true
			end
		end
	end

	return false
end

function SWEP:InitialiseGrenadeThrow()
	CT = CurTime()

	self:EmitSound("weapons/weapon_holster" .. math.random(1, 3) .. ".wav", 50, 100)
	self:PlayHolsterAnim()
	self:DelayMe(CT + 5)
	self.TimeToAdvance = CT + (self.HolsterTime and self.HolsterTime or 0.45)
	self.AdvanceStage = "draw"
	self.dt.Status = FAS_STAT_QUICKGRENADE
end

function SWEP:DrawGrenade()
	if SP and SERVER then
		SendUserMessage("FAS2_DRAWGRENADE", self.Owner)
	end

	if CLIENT then
		FAS2_DrawGrenade()
	end

	self.AdvanceStage = "prepare"
	self.TimeToAdvance = CT + 0.1
end

function SWEP:AdvanceGrenadeThrow()
	CT = CurTime()

	self.Cooking = true
	self.FuseTime = CT + 3.5
	self.CookTime = CT + 3.5
	self.TimeToAdvance = nil
	self.ThrowPower = 0.5
	self.TimeToThrow = CT + 0.6

	if SP and SERVER then
		SendUserMessage("FAS2_PULLPIN", self.Owner)
	end

	if CLIENT then
		FAS2_PullGrenadePin()
	end
end

local phys, force, pos, EA

function SWEP:ThrowGrenade()
	self.Cooking = false
	CT = CurTime()

	if SP and SERVER then
		SendUserMessage("FAS2_THROWGRENADE", self.Owner)
	end

	if CLIENT then
		FAS2_ThrowGrenade()
	end

	if SERVER then
		timer.Simple(0.15, function()
			if IsValid(self) and IsValid(self.Owner) and self.Owner:Alive() then
				local nade = ents.Create("fas2_thrown_m67")
				EA =  self.Owner:EyeAngles()
				pos = self.Owner:GetShootPos()
				pos = pos + EA:Right() * 5 - EA:Up() * 4 + EA:Forward() * 8

				nade:SetPos(pos)
				nade:SetAngles(Angle(math.random(0, 360), math.random(0, 360), math.random(0, 360)))
				nade:Spawn()
				nade:SetOwner(self.Owner)
				nade:Fuse(self.CookTime - CT)

				phys = nade:GetPhysicsObject()

				if IsValid(phys) then
					force = 1000

					if self.Owner:KeyDown(IN_FORWARD) and ong then
						force = force + self.Owner:GetVelocity():Length()
					end

					phys:SetVelocity(EA:Forward() * force * self.ThrowPower + Vector(0, 0, 100))
					phys:AddAngleVelocity(Vector(math.random(-500, 500), math.random(-500, 500), math.random(-500, 500)))
				end
			end
		end)
	end

	self.Owner:RemoveAmmo(1, "M67 Grenades")

	timer.Simple(0.65, function()
		if IsValid(self) and IsValid(self.Owner) and self.Owner:Alive() then
			self:DrawWeapon()
		end
	end)

	self.FuseTime = nil
end

function SWEP:DrawWeapon()
	self:DelayMe(CT + self.DeployTime)
	self:PlayDeployAnim()
	self.dt.Status = FAS_STAT_IDLE
end

function SWEP:OnRemove()
	--[[if CLIENT then
		SafeRemoveEntity(self.Wep)
		SafeRemoveEntity(self.W_Wep)
		SafeRemoveEntity(self.Nade)
	end]]--
end
