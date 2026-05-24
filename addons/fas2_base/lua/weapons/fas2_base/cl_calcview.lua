local FT, CT, vm, att, cyc, seq, vel, cos1, cos2, intensity
local Ang0, curang, curviewbob = Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0)
local math_abs = math.abs
SWEP.LerpBackSpeed = 10

CreateClientConVar("fas2_viewbob_enable", "0", true, false)
CreateClientConVar("fas2_hip_cam_lag_scale", "0.16", true, false)
CreateClientConVar("fas2_ads_visual_follow_speed", "24", true, false)
CreateClientConVar("fas2_ads_camera_follow_strength", "0.18", true, false)

local PUNCH_K = 125
local PUNCH_C = 24

-- Cached convars (CalcView runs every render frame; GetConVarNumber
-- does a string hash lookup each call which adds up at 240Hz).
local cvFov, cvBob, cvHeadbob, cvHipCamLag, cvAdsSnap, cvAdsFollowSpeed, cvAdsCamFollow

function SWEP:CalcView(ply, pos, ang, fov)
	if not cvFov     then cvFov     = GetConVar("fov_desired")            end
	if not cvBob     then cvBob     = GetConVar("fas2_viewbob_enable")    end
	if not cvHeadbob then cvHeadbob = GetConVar("fas2_headbob_intensity") end
	if not cvHipCamLag then cvHipCamLag = GetConVar("fas2_hip_cam_lag_scale") end
	if not cvAdsSnap then cvAdsSnap = GetConVar("fas2_ads_aim_snap") end
	if not cvAdsFollowSpeed then cvAdsFollowSpeed = GetConVar("fas2_ads_visual_follow_speed") end
	if not cvAdsCamFollow then cvAdsCamFollow = GetConVar("fas2_ads_camera_follow_strength") end

	fov = fov or (cvFov and cvFov:GetFloat() or 75)
	
	FT, CT = FrameTime(), CurTime()
	vm = self.Wep
	-- Cache attachment id per-weapon: LookupAttachment does a per-frame
	-- string compare across every attachment; the muzzle name is static.
	if self._muzzleAttId == nil then
		self._muzzleAttId = vm:LookupAttachment((self.MuzzleName and self.MuzzleName or "muzzle")) or -1
	end
	att = self._muzzleAttId >= 1 and vm:GetAttachment(self._muzzleAttId) or nil
	seq = vm:GetSequenceName(vm:GetSequence())
	cyc = vm:GetCycle()
	intensity = cvHeadbob and cvHeadbob:GetFloat() or 0
	
	if att then
		if self.CurAnim and (self.CurAnim:find("reload") or self.AnimOverride and self.AnimOverride[self.CurAnim]) then
			if cyc <= 0.9 then
				self.LerpBackSpeed = 1
				ang = ang * 1
				curang = LerpAngle(FT * 10, curang, (ang - att.Ang) * 0.1)
			else
				self.LerpBackSpeed = math.Approach(self.LerpBackSpeed, 10, FT * 50)
				curang = LerpAngle(FT * self.LerpBackSpeed, curang, Ang0)
			end
		else
			curang = LerpAngle(FT * 10, curang, Ang0)
		end
	
		ang:RotateAroundAxis(ang:Right(), curang.p * self.PitchMod)
		ang:RotateAroundAxis(ang:Up(), curang.r * self.YawMod)
	end
	
	-- Single source of truth for the ADS<->hip ease; everything stance-dependent
	-- below blends through this rather than checking the boolean status flag.
	local adsFrac = self.GetAdsFrac and self:GetAdsFrac() or (self.dt.Status == FAS_STAT_ADS and 1 or 0)
	local hipMix = 1 - adsFrac

	if self.dt.Status == FAS_STAT_ADS then
		self.CurFOVMod = Lerp(FT * 10, self.CurFOVMod, self.AimFOV)
	else
		self.CurFOVMod = Lerp(FT * 10, self.CurFOVMod, 0)
	end

	fov = fov - self.CurFOVMod

	local bobEnabled = cvBob and cvBob:GetBool() or false
	local bobTarget = Angle(0, 0, 0)
	if bobEnabled and intensity > 0 then
		vel = self.Owner:GetVelocity():Length()
		local adsMul = 1 + (0.15 - 1) * adsFrac

		if self.Owner:OnGround() and vel > self.Owner:GetWalkSpeed() * 0.3 then
			-- Continuous bob scaling: instead of two discrete walk/run bands,
			-- both frequency and amplitude blend linearly with the player's
			-- speed ratio. Walking gently bobs the muzzle; sprinting whips
			-- it harder and faster, and everything between is smooth — so
			-- the gun visibly weighs more as you accelerate and lightens
			-- back as you brake.
			local ws = self.Owner:GetWalkSpeed()
			local rs = self.Owner:GetRunSpeed()
			if rs <= ws then rs = ws + 1 end
			-- speedRatio: 0 at walk speed, 1 at run speed, clamped 0..1.5
			-- so over-speed (jump-boosts, props) still scales sanely.
			local speedRatio = math.Clamp((vel - ws) / (rs - ws), 0, 1.5)
			local freqP = 15 + speedRatio * 7  -- 15..22 Hz pitch
			local freqY = 12 + speedRatio * 6  -- 12..18 Hz yaw
			local ampP  = 0.15 + speedRatio * 0.12 -- 0.15..0.27
			local ampY  = 0.10 + speedRatio * 0.07 -- 0.10..0.17
			cos1 = math.cos(CT * freqP)
			cos2 = math.cos(CT * freqY)
			bobTarget.p = cos1 * ampP * intensity * adsMul
			bobTarget.y = cos2 * ampY * intensity * adsMul
		end
	end
	curviewbob = LerpAngle(FT * (bobEnabled and 10 or 14), curviewbob, bobTarget)

	if not self._punchAng then self._punchAng = Angle(0,0,0) end
	if not self._punchVel then self._punchVel = Angle(0,0,0) end

	if FT > 0 then
		local pa, pv = self._punchAng, self._punchVel
		pv.p = pv.p + (-PUNCH_K * pa.p - PUNCH_C * pv.p) * FT
		pv.y = pv.y + (-PUNCH_K * pa.y - PUNCH_C * pv.y) * FT
		pv.r = pv.r + (-PUNCH_K * pa.r - PUNCH_C * pv.r) * FT
		pa.p = pa.p + pv.p * FT
		pa.y = pa.y + pv.y * FT
		pa.r = pa.r + pv.r * FT

		if math_abs(pa.p) < 0.001 and math_abs(pv.p) < 0.01 then pa.p = 0; pv.p = 0 end
		if math_abs(pa.y) < 0.001 and math_abs(pv.y) < 0.01 then pa.y = 0; pv.y = 0 end
		if math_abs(pa.r) < 0.001 and math_abs(pv.r) < 0.01 then pa.r = 0; pv.r = 0 end
	end

	local patIdx = self.PatternIndex or 0
	local timeSinceFire = CT - (self.LastFireTime or 0)
	local resetWin = self.GetEffectiveSprayResetTime and self:GetEffectiveSprayResetTime() or (self.SprayResetTime or 0.35)
	local isSpraying = patIdx >= 1 and timeSinceFire <= resetWin

	-- Camera lag accumulator: keep updating it regardless of ADS state so that
	-- when the player drops out of ADS mid-spray it's still pointing at the
	-- right rolling-average value, then scale the display by hipMix so ADS
	-- smoothly hides the hipfire-style camera kick instead of zeroing it
	-- the instant the status flag flips.
	local targetP = self._camAccP or 0
	local targetY = self._camAccY or 0

	if not isSpraying then
		local decay = 1 - math.min(FT * 14, 1)
		targetP = targetP * decay
		targetY = targetY * decay
		if math_abs(targetP) < 0.01 then targetP = 0 end
		if math_abs(targetY) < 0.01 then targetY = 0 end
	end

	self._camAccP = targetP
	self._camAccY = targetY

	local smoothSpeed = isSpraying and 18 or 14
	local hipCamScale = cvHipCamLag and cvHipCamLag:GetFloat() or 0.16
	hipCamScale = math.Clamp(hipCamScale, 0, 1)
	self._smoothCamP = Lerp(FT * smoothSpeed, self._smoothCamP or 0, targetP * hipMix * hipCamScale)
	self._smoothCamY = Lerp(FT * smoothSpeed, self._smoothCamY or 0, targetY * hipMix * hipCamScale)

	local followTargetP, followTargetY = 0, 0
	local followStrength = cvAdsSnap and cvAdsSnap:GetFloat() or 1
	followStrength = followStrength * (cvAdsCamFollow and cvAdsCamFollow:GetFloat() or 0.18)
	if followStrength > 0 and adsFrac > 0.001 and isSpraying and self.GetSprayOffset and self.GetMovementBias then
		local nextIdx = patIdx + 1
		local nextP, nextY = self:GetSprayOffset(nextIdx, adsFrac)
		local biasP, biasY = self:GetMovementBias(adsFrac)

		-- Visual-only ADS follow. Do not rotate EyeAngles here; the bullet
		-- path already points at this same offset, so moving CalcView at
		-- render-frame speed makes the iron sight sit on the next round
		-- without server/client tick jitter.
		followTargetP = (nextP - (self._sprayLiftP or 0) + biasP) * adsFrac * followStrength
		followTargetY = (nextY - (self._sprayLiftY or 0) + biasY) * adsFrac * followStrength
	end

	local followSpeed = cvAdsFollowSpeed and cvAdsFollowSpeed:GetFloat() or 24
	followSpeed = math.Clamp(followSpeed, 1, 120)
	local activeFollowSpeed = isSpraying and followSpeed or math.min(followSpeed, 12)
	local followLerp = math.min(FT * activeFollowSpeed, 1)
	self._adsVisualFollowP = Lerp(followLerp, self._adsVisualFollowP or 0, followTargetP)
	self._adsVisualFollowY = Lerp(followLerp, self._adsVisualFollowY or 0, followTargetY)
	if math_abs(self._adsVisualFollowP) < 0.001 then self._adsVisualFollowP = 0 end
	if math_abs(self._adsVisualFollowY) < 0.001 then self._adsVisualFollowY = 0 end

	ang.p = ang.p + self._adsVisualFollowP + self._smoothCamP + self._punchAng.p
	ang.y = ang.y + self._adsVisualFollowY + self._smoothCamY + self._punchAng.y
	ang.r = ang.r + self._punchAng.r

	return pos, ang + curviewbob, fov
end

-- Public hook for sh_bullet to inject a per-shot impulse into the
-- critically-damped spring above. Acts as a smooth settling tail on top
-- of the engine's ViewPunch snap — the snap gives instant feedback, this
-- gives the slow CS2-style return to center. Scale << 1 so we don't
-- double the felt kick.
function SWEP:AddRecoilImpulse(impulseAng)
	if not impulseAng then return end
	if not self._punchAng then self._punchAng = Angle(0, 0, 0) end
	if not self._punchVel then self._punchVel = Angle(0, 0, 0) end
	-- Blend the spring impulse scale so per-shot kick magnitude doesn't
	-- step mid-spray when the player taps ADS on or off.
	local adsFrac = self.GetAdsFrac and self:GetAdsFrac() or (self.dt and self.dt.Status == FAS_STAT_ADS and 1 or 0)
	local s = 0.32 + (0.24 - 0.32) * adsFrac
	self._punchVel.p = self._punchVel.p + impulseAng.p * s
	self._punchVel.y = self._punchVel.y + impulseAng.y * s
	self._punchVel.r = self._punchVel.r + impulseAng.r * s
end

function SWEP:AdjustMouseSensitivity()
	if self.dt.Status == FAS_STAT_ADS then

		if self.Peeking then
			return 0.5
		end
		
		if self.AimSens then
			return self.AimSens * self.MouseSensMod * (self.dt.Bipod and 0.7 or 1)
		end
		
		if self.AimPos == self.ACOGPos or self.AimPos == self.PSO1Pos or self.AimPos == self.ELCANPos then
			return 0.2 * self.MouseSensMod * (self.dt.Bipod and 0.7 or 1)
		elseif self.AimPos == self.LeupoldPos then
			return 0.15 * self.MouseSensMod * (self.dt.Bipod and 0.7 or 1)
		end
	end
		
	return 1 * self.MouseSensMod * (self.dt.Bipod and 0.7 or 1)
end
