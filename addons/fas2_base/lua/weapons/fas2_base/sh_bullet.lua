--[[
	BALLISTIC LAYER: Rust-grade projectile simulation
	Three-layer: this is Layer 3. Consumes spray direction from RecoilBrain.
	Applies: movement spread, cone spread, bullet drop, damage falloff, tagging.

	Perf/realism notes (May 2026):
	  * No per-shot closures: bullet callbacks are reused module-local functions
	    that read the active SWEP from `_activeSWEP`. Eliminates ~1 closure +
	    ~3 upvalue captures per pellet per shot (huge GC win under sustained
	    automatic fire / shotgun blasts).
	  * Deterministic cone RNG: `util.SharedRandom` keyed on CmdNum + shot index
	    so client prediction and server authority agree to the bullet, killing
	    "ghost shot" feel.
	  * Predicted camera kick: small `Player:ViewPunch` per shot for CS2-style
	    visible recoil, scaled by pattern index and stance. The pattern itself
	    still walks bullets up; the punch is purely feel.
]]
local Dir, Dir2, dot, sp, ent, trace, seed, hm
local trace_normal = bit.bor(CONTENTS_SOLID, CONTENTS_OPAQUE, CONTENTS_MOVEABLE, CONTENTS_DEBRIS, CONTENTS_MONSTER, CONTENTS_HITBOX, 402653442, CONTENTS_WATER)
local trace_walls = bit.bor(CONTENTS_TESTFOGVOLUME, CONTENTS_EMPTY, CONTENTS_MONSTER, CONTENTS_HITBOX)
local NoPenetration = {[MAT_SLOSH] = true}
local NoRicochet = {[MAT_FLESH] = true, [MAT_ANTLION] = true, [MAT_BLOODYFLESH] = true, [MAT_DIRT] = true, [MAT_SAND] = true, [MAT_GLASS] = true, [MAT_ALIENFLESH] = true}
local PenMod = {[MAT_SAND] = 0.5, [MAT_DIRT] = 0.8, [MAT_METAL] = 1.1, [MAT_TILE] = 0.9, [MAT_WOOD] = 1.2}
local bul, tr = {}, {}
local SP = game.SinglePlayer()

local reg = debug.getregistry()
local GetShootPos = reg.Player.GetShootPos
local GetCurrentCommand = reg.Player.GetCurrentCommand
local CommandNumber = reg.CUserCmd.CommandNumber

local math_Round  = math.Round
local math_max    = math.max
local math_Clamp  = math.Clamp
local math_Rand   = math.Rand

-- Forward decl: defined further down but referenced inside the
-- _PrimaryCallback closure above its definition.
local CalcDamageFalloff
local math_deg    = math.deg
local math_atan2  = math.atan2
local math_random = math.random
local util_SharedRandom = util.SharedRandom

local _spreadAng = Angle(0, 0, 0)
local _dropAng   = Angle(0, 0, 0)
local _kickAng   = Angle(0, 0, 0)
local _preTrace  = {}
local _zeroVec   = Vector(0, 0, 0)

-- Active SWEP for the in-flight bullet callbacks. Set just before FireBullets
-- so the reusable callbacks below can read per-shot context without forming
-- a closure (closures = allocations = GC stutter).
local _activeSWEP = nil
local _activeShootPos
local _activeBaseDmg
local _activeEffRange
local _activeFalloff
local _activeHM
local _activeAmmo  -- "", "hv", or "volatile" — drives tracer + muzzle tint

local function _PrimaryCallback(_, btr, dmg)
	local e = btr.Entity
	local hitDist = btr.HitPos:Distance(_activeShootPos)

	local finalDmg = CalcDamageFalloff(hitDist, _activeEffRange, _activeFalloff, _activeBaseDmg)
	if finalDmg ~= _activeBaseDmg then
		dmg:SetDamage(finalDmg)
	end

	if SERVER then
		if e:IsPlayer() and e:Alive() then
			local tagStr = math_Clamp(finalDmg / _activeBaseDmg, 0.1, 1) * 0.3
			local curVel = e:GetVelocity()
			e:SetVelocity(curVel * -tagStr)

			local tagEnt = e
			timer.Simple(0.4, function()
				if IsValid(tagEnt) and tagEnt:Alive() then
					tagEnt:SetVelocity(_zeroVec)
				end
			end)
		end
	end

	if _activeHM > 0 and (e:IsNPC() or e:IsPlayer()) then
		-- Classify hit: HITGROUP_HEAD = 1, target HP <= damage → kill.
		local kind = "body"
		if btr.HitGroup == HITGROUP_HEAD then kind = "head" end
		if e.Health and e:Health() <= finalDmg then kind = "kill" end

		if SERVER and SP then
			SendUserMessage("FAS2_HITMARKER", _activeSWEP.Owner)
		end
		if CLIENT then
			_activeSWEP.HitMarkerTime  = CurTime() + 0.2
			_activeSWEP.HitMarkerAlpha = 255
			_activeSWEP.HitMarkerKind  = kind

			-- Audio sting (only for local shooter).
			if _activeSWEP.Owner == LocalPlayer() then
				if kind == "head" then
					surface.PlaySound("physics/glass/glass_impact_bullet1.wav")
				elseif kind == "kill" then
					surface.PlaySound("buttons/button17.wav")
				else
					surface.PlaySound("common/wpn_select.wav")
				end
			end
		end
	end
end

local function _PenetrationCallback(_, btr, _)
	local e = btr.Entity
	if _activeHM > 0 and (e:IsNPC() or e:IsPlayer()) then
		if SERVER and SP then
			SendUserMessage("FAS2_HITMARKER", _activeSWEP.Owner)
		end
		if CLIENT then
			_activeSWEP.HitMarkerTime  = CurTime() + 0.2
			_activeSWEP.HitMarkerAlpha = 255
			_activeSWEP.HitMarkerKind  = "body"
		end
	end
end

local function CalcBulletDrop(dist, muzzleVel, gravity)
	local travelTime = dist / muzzleVel
	return 0.5 * gravity * travelTime * travelTime
end

local function CalcZeroedDrop(dist, muzzleVel, gravity, zeroDist)
	local drop = CalcBulletDrop(dist, muzzleVel, gravity)
	if not zeroDist or zeroDist <= 0 then
		return drop
	end

	local zeroLift = CalcBulletDrop(zeroDist, muzzleVel, gravity) * (dist / zeroDist)
	return drop - zeroLift
end

function CalcDamageFalloff(dist, effectiveRange, falloffRate, baseDmg)
	if dist <= effectiveRange then return baseDmg end
	local overRange = (dist - effectiveRange) / effectiveRange
	return math_Round(math_max(baseDmg * (1 - overRange * falloffRate), baseDmg * 0.15))
end

function SWEP:FireBullet()
	if CLIENT then
		hm = GetConVarNumber("fas2_hitmarker")
	else
		if SP then
			hm = tonumber(self.Owner:GetInfo("fas2_hitmarker"))
		end
	end

	sp = GetShootPos(self.Owner)

	if self.UpdateAdsAimSnap then
		self:UpdateAdsAimSnap()
	end

	self:AdvanceSpray()
	Dir = self:GetSprayDirection()

	local sprayIdx = self.PatternIndex or 0
	local sprayScale = math_Clamp((sprayIdx - 5) / 12, 0, 1)

	-- Stance/movement accuracy: applies even on shot 1 (movementCone) and
	-- scales the late-spray cone (coneMult). Standing still / counter-strafed
	-- => coneMult=1, movementCone=0, so behavior matches the recorded pattern.
	local stanceCone, stanceAdd, stanceSpeed = 1, 0, 0
	if self.GetStanceAccuracy then
		local s = self:GetStanceAccuracy()
		if s then
			stanceCone  = s.coneMult or 1
			stanceAdd   = s.movementCone or 0
			stanceSpeed = s.speed or 0
		end
	end

	local totalCone = (self.CurCone or 0) * sprayScale * stanceCone + stanceAdd

	-- Sweet-spot rule: within the weapon's effective sweet-spot range the
	-- random cone is zeroed so bullets follow the deterministic spray
	-- pattern exactly. That means the follow-recoil dot IS truth — put it
	-- on the head, get the headshot. Beyond sweet-spot the cone grows
	-- back in linearly, so long-range sprays still feel realistic.
	if totalCone > 0.001 then
		local sweetRange = (self.GetEffectiveSweetSpotRange and self:GetEffectiveSweetSpotRange())
			or self.EffectiveRange or 3000
		_preTrace.start  = sp
		_preTrace.endpos = sp + Dir * 32768
		_preTrace.filter = self.Owner
		_preTrace.mask   = trace_normal
		local hd = util.TraceLine(_preTrace).HitPos:Distance(sp)
		if hd <= sweetRange then
			totalCone = 0
		else
			local over = (hd - sweetRange) / sweetRange
			totalCone = totalCone * math_Clamp(over, 0, 1.5)
		end
	end

	-- Deterministic shared RNG: same CmdNum + shotIdx on client and server
	-- produce identical spread, so prediction matches authority. No more
	-- math.randomseed(CurTime()) which silently desynced under packet loss.
	local cmd = GetCurrentCommand(self.Owner)
	local cmdNum = cmd and CommandNumber(cmd) or 0
	local seedKey = "FAS2_" .. (self.Class or "x") .. "_" .. cmdNum .. "_" .. sprayIdx

	if totalCone > 0.001 then
		local rp = util_SharedRandom(seedKey .. "p", -totalCone, totalCone, 0)
		local ry = util_SharedRandom(seedKey .. "y", -totalCone, totalCone, 1)
		-- Random component is intentionally small (was *4): the bulk of
		-- movement spread is now the deterministic GetMovementBias() lean
		-- folded into GetSprayDirection, which the follow-recoil dot also
		-- accounts for. Keep ~1.6x so there's still some live jitter, but
		-- the dot remains a reliable predictor of where rounds go.
		_spreadAng = Dir:Angle()
		_spreadAng.p = _spreadAng.p + rp * 1.6
		_spreadAng.y = _spreadAng.y + ry * 1.6
		Dir = _spreadAng:Forward()
	end

	-- Predicted view-punch (CS2-style camera kick). The actual bullet
	-- direction is unaffected; this is feel only. First shots punch hardest,
	-- later shots taper because the player is fighting the pattern already.
	-- Movement amplifies the felt kick (loose stance = jarring).
	-- ADS shoulders the rifle into the camera, so the camera takes the
	-- shake; hipfire keeps the camera mostly steady so the player can read
	-- the follow-recoil dot and the viewmodel does the visual work.
	if self.GetSprayOffset then
		-- Eased ADS fraction: 0 hipfire, 1 full ADS. All stance-dependent
		-- numbers below blend through this so spraying while toggling ADS
		-- feels like one continuous recoil curve instead of a hard switch.
		local adsFrac = self.GetAdsFrac and self:GetAdsFrac() or (self.dt.Status == FAS_STAT_ADS and 1 or 0)
		local kP, kY = self:GetSprayOffset(sprayIdx, adsFrac)
		local kickDecay = 1 / (1 + sprayIdx * 0.18)
		local stanceKick = 1 + math_Clamp((stanceSpeed - 6) / 220, 0, 1) * 0.6
		local weaponKick = self.ViewPunchScale or 1
		local stanceMode = 0.9 + (0.72 - 0.9) * adsFrac
		local statKick = math_Clamp(math.max(tonumber(self.ViewKick) or 0, tonumber(self.Recoil) or 0, 0.35), 0.35, 5.5)
		-- ViewPunch is only a tiny tactile shake. The first-shot pop now
		-- lives in the pattern startup itself, so bullet, dot, and camera
		-- all agree instead of the crosshair being punched away alone.
		local firstShotKick = sprayIdx == 1 and 0.060 or 0.050
		local statPunch = statKick * firstShotKick
		local patternPunch = math.abs(kP) * 0.050
		local kFactor = kickDecay * stanceKick * weaponKick * stanceMode
		_kickAng.p = -(statPunch + patternPunch) * kFactor
		_kickAng.y = (kY * 0.050 + math.sin(sprayIdx * 2.37) * statPunch * 0.025) * kFactor
		local rollMode = 0.25 + (0.45 - 0.25) * adsFrac
		_kickAng.r = kY * 0.020 * kickDecay * rollMode
		self.Owner:ViewPunch(_kickAng)

		-- Sub-frame settling tail via the cl_calcview spring (client only).
		if CLIENT and self.AddRecoilImpulse and self.Owner == LocalPlayer() then
			self:AddRecoilImpulse(_kickAng)
		end

		-- CS-style PERMANENT view lift driven by the pattern delta. ViewPunch
		-- alone decays in a few frames, so the player never has to "fight"
		-- the spray with mouse-down. This shifts EyeAngles by the per-shot
		-- delta so the camera actually tracks the pattern, and the player's
		-- mouse compensation has something to push back against.
		--
		-- Sign convention: in FA:S base, negative pattern pitch = recoils UP
		-- (bullets visually rise, e.g. AK `{-0.12, 0.03}`). Adding dP to
		-- EyeAngles.p with negative dP decreases pitch → camera looks UP.
		-- For patterns recorded with inverted sign (positive p meaning
		-- "bullets fall"), set SWEP.RecoilLiftScale = -1 to flip per-weapon,
		-- or use the global convar `fas2_recoil_lift_scale`.
		if IsValid(self.Owner) and self.Owner:IsPlayer() and (SERVER or (CLIENT and self.Owner == LocalPlayer())) then
			local prevP, prevY = 0, 0
			if sprayIdx > 1 then prevP, prevY = self:GetSprayOffset(sprayIdx - 1, adsFrac) end
			local dP = kP - prevP
			local dY = kY - prevY
			-- ADS = 1.0 so the camera fully tracks the pattern and the iron
			-- sights stay glued to where bullets land. Hip = 0.5 so the gun
			-- visibly drifts and the follow-recoil dot has real predictive
			-- value. Both stances now produce bullets at the SAME absolute
			-- position thanks to the lift-accumulator compensation in
			-- GetSprayDirection — ADS/hip toggling mid-spray no longer
			-- splits impacts into two clusters.
			local liftMode  = 0.50 + (1.00 - 0.50) * adsFrac
			local liftScale = (self.RecoilLiftScale or 1) * (FAS2_RecoilLiftScale or 1)
			-- Pure pattern lift only — no per-shot bonus terms. Anything else
			-- baked in here would desync the accumulator from the pattern and
			-- shift bullets off the dot's prediction. First-shot pop is
			-- handled by ViewPunch above (`tapPunch`) so the feel is kept
			-- without polluting bullet aim.
			local appliedP = dP * liftScale * liftMode
			local appliedY = dY * liftScale * liftMode
			local ea = self.Owner:EyeAngles()
			ea.p = math.Clamp(ea.p + appliedP, -89, 89)
			ea.y = ea.y + appliedY
			self.Owner:SetEyeAngles(ea)

			-- Track exactly what we just pushed into EyeAngles so the next
			-- GetSprayDirection / GetNextBulletScreenPos call can subtract
			-- it back out. Invariant:
			--   bullet absolute aim == orig_aim + pattern[idx] + bias
			self._sprayLiftP = (self._sprayLiftP or 0) + appliedP
			self._sprayLiftY = (self._sprayLiftY or 0) + appliedY
		end
	end

	local muzzleVel, gravity, zeroDist = self:GetBallisticTuning()
	local doBulletDrop = self.BulletDrop ~= false
	local effRange = (self.GetEffectiveSweetSpotRange and self:GetEffectiveSweetSpotRange())
		or self.EffectiveRange or 3000
	local falloff = self.DamageFallOff or 0.5
	local baseDmg = math_Round(self.Damage)

	-- Publish per-shot context for the reusable bullet callbacks (zero alloc).
	_activeSWEP     = self
	_activeShootPos = sp
	_activeBaseDmg  = baseDmg
	_activeEffRange = effRange
	_activeFalloff  = falloff
	_activeHM       = hm or 0
	_activeAmmo     = self.GetNW2String and self:GetNW2String("FAS2_AmmoOverride", "") or ""

	-- Ammo-aware tracer: HV reads as a blue energy bolt, volatile as a hot
	-- orange round, standard stays vanilla. TracerName is engine-side so all
	-- players see the visual, not just the shooter.
	local tracerName
	if     _activeAmmo == "hv"       then tracerName = "AR2Tracer"
	elseif _activeAmmo == "volatile" then tracerName = "AirboatGunHeavyTracer"
	end

	-- Local-prediction muzzle flash tint: brief colored dlight at the shoot
	-- position so the shooter feels the ammo type. Doesn't broadcast —
	-- TracerName above already gives every player a visual cue.
	if CLIENT and _activeAmmo ~= "" and self.Owner == LocalPlayer() then
		local dl = DynamicLight(self:EntIndex())
		if dl then
			dl.Pos        = sp + Dir * 8
			dl.Size       = 220
			dl.Decay      = 1800
			dl.Brightness = 2
			dl.DieTime    = CurTime() + 0.06
			if _activeAmmo == "hv" then
				dl.r, dl.g, dl.b = 120, 200, 255
			else -- volatile
				dl.r, dl.g, dl.b = 255, 150, 70
			end
		end
	end

	for i = 1, self.Shots do
		Dir2 = Dir

		if self.ClumpSpread and self.ClumpSpread > 0 then
			local cx = util_SharedRandom(seedKey .. "cx" .. i, -1, 1, 2 + i)
			local cy = util_SharedRandom(seedKey .. "cy" .. i, -1, 1, 3 + i)
			local cz = util_SharedRandom(seedKey .. "cz" .. i, -1, 1, 4 + i)
			Dir2 = Dir + Vector(cx, cy, cz) * self.ClumpSpread
		end

		local fireDir = Dir2

		if doBulletDrop then
			_preTrace.start = sp
			_preTrace.endpos = sp + Dir2 * 32768
			_preTrace.filter = self.Owner
			_preTrace.mask = trace_normal
			local preResult = util.TraceLine(_preTrace)
			local hitDist = preResult.HitPos:Distance(sp)

			if hitDist > 256 then
				local drop = CalcZeroedDrop(hitDist, muzzleVel, gravity, zeroDist)
				_dropAng = Dir2:Angle()
				_dropAng.p = _dropAng.p + math_deg(math_atan2(drop, hitDist))
				fireDir = _dropAng:Forward()
			end
		end

		bul.Num = 1
		bul.Src = sp
		bul.Dir = fireDir
		bul.Spread = _zeroVec
		bul.Tracer = 1
		bul.TracerName = tracerName
		bul.Force = baseDmg * 0.1
		bul.Damage = baseDmg
		bul.Callback = _PrimaryCallback
		
		self.Owner:FireBullets(bul)
		
		tr.start = sp
		tr.endpos = tr.start + fireDir * 16384
		tr.filter = self.Owner
		tr.mask = trace_normal
		
		trace = util.TraceLine(tr)
			
		if not NoPenetration[trace.MatType] then
			dot = -fireDir:DotProduct(trace.HitNormal)
			ent = trace.Entity
		
			if self.PenetrationEnabled and dot > 0.26 and not ent:IsNPC() and not ent:IsPlayer() then
				tr.start = trace.HitPos
				tr.endpos = tr.start + fireDir * self.PenStr * (PenMod[trace.MatType] and PenMod[trace.MatType] or 1) * self.PenMod
				tr.filter = self.Owner
				tr.mask = trace_walls
				
				trace = util.TraceLine(tr)
				
				tr.start = trace.HitPos
				tr.endpos = tr.start + fireDir * 0.1
				tr.filter = self.Owner
				tr.mask = trace_normal
				
				trace = util.TraceLine(tr)
				
				if not trace.Hit then
					bul.Num = 1
					bul.Src = trace.HitPos
					bul.Dir = fireDir
					bul.Spread = _zeroVec
					bul.Tracer = 4
					bul.TracerName = tracerName
					bul.Force = baseDmg * 0.05
					bul.Damage = bul.Damage * 0.5

					bul.Callback = _PenetrationCallback

					self.Owner:FireBullets(bul)

					bul.Num = 1
					bul.Src = trace.HitPos
					bul.Dir = -fireDir
					bul.Spread = _zeroVec
					bul.Tracer = 4
					bul.TracerName = tracerName
					bul.Force = baseDmg * 0.05
					bul.Damage = bul.Damage * 0.5

					bul.Callback = _PenetrationCallback

					self.Owner:FireBullets(bul)
				end
			else
				if self.RicochetEnabled then
					if not NoRicochet[trace.MatType] then
						local ricoDir = fireDir + (trace.HitNormal * dot) * 3
						ricoDir = ricoDir + VectorRand() * 0.06
						bul.Num = 1
						bul.Src = trace.HitPos
						bul.Dir = ricoDir
						bul.Spread = _zeroVec
						bul.Tracer = 0
						bul.Force = baseDmg * 0.075
						bul.Damage = bul.Damage * 0.75

						bul.Callback = _PenetrationCallback

						self.Owner:FireBullets(bul)
					end
				end
			end
		end
	end
		
	tr.mask = trace_normal
end
