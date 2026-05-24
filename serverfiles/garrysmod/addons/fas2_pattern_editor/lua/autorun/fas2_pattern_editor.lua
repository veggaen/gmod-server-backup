if SERVER then
    AddCSLuaFile()
end

FAS2PatternEditor = FAS2PatternEditor or {}

local EDITOR = FAS2PatternEditor
EDITOR.Patterns = EDITOR.Patterns or {}
EDITOR.ActivePainters = EDITOR.ActivePainters or {}
EDITOR.DataDir = "fas2_pattern_editor"
EDITOR.DataFile = EDITOR.DataDir .. "/patterns.json"
EDITOR.EditorVersion = "professional-v3-ads-guide"
EDITOR.RecommendedCalibrationUnits = 984
EDITOR.MinCalibrationUnits = 590
EDITOR.MaxCalibrationUnits = 2362
EDITOR.CommandAliases = {
    ["!faspattern"] = true,
    ["!fas"] = true,
    ["!faspat"] = true,
    ["!pattern"] = true,
    ["!spray"] = true,
    ["/faspattern"] = true,
    ["/fas"] = true,
    ["/faspat"] = true,
    ["/pattern"] = true,
    ["/spray"] = true,
    ["!fasrecalibrate"] = true,
    ["/fasrecalibrate"] = true,
    ["!faspatterneditor"] = true,
    ["/faspatterneditor"] = true,
    ["!fasseed"] = true,
    ["/fasseed"] = true,
}

local function normalizeAngle(angleValue)
    angleValue = angleValue or 0

    while angleValue > 180 do
        angleValue = angleValue - 360
    end

    while angleValue < -180 do
        angleValue = angleValue + 360
    end

    return angleValue
end

local function getWeaponClass(weapon)
    if not IsValid(weapon) then
        return nil
    end

    local className = weapon.GetClass and weapon:GetClass() or weapon.ClassName
    if not className or className == "" then
        return nil
    end

    return className
end

local function splitWords(text)
    local words = {}

    for word in string.gmatch(text or "", "%S+") do
        table.insert(words, word)
    end

    return words
end

function EDITOR.IsSupportedWeapon(weapon)
    if not IsValid(weapon) then
        return false
    end

    local className = getWeaponClass(weapon)
    if not className or string.sub(className, 1, 5) ~= "fas2_" then
        return false
    end

    return weapon.IsFAS2Weapon == true or weapon.Base == "fas2_base" or weapon.Base == "fas2_base_shotgun"
end

function EDITOR.GetClipSize(weapon)
    if not IsValid(weapon) then
        return 0
    end

    local clipSize = 0

    if weapon.GetMaxClip1 then
        clipSize = tonumber(weapon:GetMaxClip1()) or 0
    end

    if clipSize <= 0 and weapon.Primary then
        clipSize = tonumber(weapon.Primary.ClipSize) or 0
    end

    if clipSize < 0 then
        clipSize = 0
    end

    return math.floor(clipSize)
end

function EDITOR.ResetWeaponState(weapon)
    if not IsValid(weapon) then
        return
    end

    local owner = weapon.Owner or weapon:GetOwner()
    if IsValid(owner) and owner.SetPunchAngle then
        owner:SetPunchAngle(Angle(0, 0, 0))
    end

    weapon.FAS2PatternShotCount = 0
    weapon.FAS2PatternCurrentPointIndex = nil
    weapon.FAS2PatternLastShotTime = 0
    weapon.FAS2PatternBaseAngles = nil
    weapon.FAS2PatternTargetAngles = nil
    weapon.FAS2PatternAccumulated = nil
end

function EDITOR.ApplyPatternVisualKick(weapon, owner, isAiming, pitchDelta, yawDelta, mul)
    if not CLIENT or not IsValid(weapon) or not IsValid(owner) or not owner.ViewPunch then
        return
    end

    local spreadScale = 1 + (tonumber(weapon.AddSpread) or 0) * (tonumber(weapon.SpreadToRecoil) or 1)
    local stanceScale = owner:Crouching() and 0.75 or 1
    local bipodScale = weapon.dt and weapon.dt.Bipod and 0.3 or 1
    local baseScale = spreadScale * stanceScale * bipodScale * (tonumber(mul) or 1)
    local recoilValue = math.max(math.abs(tonumber(weapon.Recoil) or 0), 0.001)
    local viewKick = tonumber(weapon.ViewKick) or recoilValue
    local yawLimit = isAiming and 0.2475 or 0.33
    local yawScale = math.Clamp((tonumber(yawDelta) or 0) / recoilValue, -1, 1) * yawLimit

    owner:ViewPunch(Angle(-viewKick, viewKick * yawScale, 0) * baseScale)
end

function EDITOR.GetPatternFollowPoint(weapon, pattern)
    if not IsValid(weapon) or type(pattern) ~= "table" or type(pattern.points) ~= "table" or #pattern.points == 0 then
        return nil
    end

    local pointIndex = math.min(tonumber(weapon.FAS2PatternCurrentPointIndex) or 0, #pattern.points)
    local resetDelay = EDITOR.GetResetDelay(weapon, pattern)
    local lastShotTime = weapon.FAS2PatternLastShotTime or 0
    local currentTime = CurTime()

    if pointIndex <= 0 or lastShotTime <= 0 then
        return nil
    end

    local elapsed = math.max(currentTime - lastShotTime, 0)
    if elapsed >= resetDelay then
        return nil
    end

    local point = pattern.points[pointIndex]
    if type(point) ~= "table" then
        return nil
    end

    local recovery = math.Clamp(elapsed / resetDelay, 0, 1)
    local springScale = 1 - recovery
    springScale = springScale * springScale

    return {
        p = (tonumber(point.p) or 0) * springScale,
        y = (tonumber(point.y) or 0) * springScale,
    }
end

function EDITOR.DrawFollowRecoilDot(weapon)
    if not CLIENT or not EDITOR.ShouldUseCustomRecoil(weapon) then
        return
    end

    if EDITOR.ClientState and EDITOR.ClientState.active then
        return
    end

    local owner = weapon.Owner or weapon:GetOwner()
    if not IsValid(owner) then
        return
    end

    local pattern = EDITOR.GetPattern(weapon)
    if not pattern then
        return
    end

    -- Use the native PatternIndex to detect if we're actively spraying.
    -- The native system tracks this via AdvanceSpray / CalcView.
    local patIdx = weapon.PatternIndex or 0
    local sprayProgress = weapon.GetSprayProgress and weapon:GetSprayProgress(CurTime()) or (weapon.SprayProgress or patIdx)
    local lastFireTime = weapon.LastFireTime or 0
    local timeSinceFire = CurTime() - lastFireTime
    local recoveryDelay = weapon.GetSprayRecoveryDelay and weapon:GetSprayRecoveryDelay() or 0.085

    -- Also check the weapon's custom spring state for bounce residue.
    local punchAng = weapon._punchAng or Angle(0, 0, 0)
    local punchMag = math.abs(punchAng.p) + math.abs(punchAng.y)
    local camMag = math.abs(weapon._smoothCamP or 0) + math.abs(weapon._smoothCamY or 0)

    -- The dot has its own slow-decay tracker, separate from the camera.
    -- Camera resets fast (responsive tapping), dot lingers and floats back
    -- slowly (CS2-style visual feedback of where your spray was).
    local dotSmoothP = weapon._dotSmoothP or 0
    local dotSmoothY = weapon._dotSmoothY or 0

    -- Hide dot when it has fully settled back to center.
    local dotMag = math.abs(dotSmoothP) + math.abs(dotSmoothY)
    if sprayProgress <= 0.001 and timeSinceFire > (weapon.GetSprayFullResetTime and weapon:GetSprayFullResetTime() or 0.52) and punchMag < 0.01 and dotMag < 0.01 then
        weapon._dotSmoothP = 0
        weapon._dotSmoothY = 0
        return
    end

    local isRecovering = sprayProgress > 0.001
    local isSpraying = isRecovering and timeSinceFire <= recoveryDelay
    local FT = FrameTime()

    -- Target position for the dot.
    local targetP, targetY = 0, 0
    if isSpraying then
        -- Active spray: dot leads to next bullet position
        local nextIdx = weapon.GetNextSprayIndex and weapon:GetNextSprayIndex(sprayProgress) or (patIdx + 1)
        local isADS = weapon.dt and weapon.dt.Status == FAS_STAT_ADS
        if weapon.GetSprayOffset then
            targetP, targetY = weapon:GetSprayOffset(nextIdx, isADS)
        end
    elseif isRecovering then
        local isADS = weapon.dt and weapon.dt.Status == FAS_STAT_ADS
        if weapon.GetSprayOffset then
            targetP, targetY = weapon:GetSprayOffset(sprayProgress, isADS)
        end
    end
    -- Recovery: targetP/Y stays 0, dot drifts back slowly.

    -- Lerp speed: fast to follow spray (30), slow to recover (3).
    -- Camera uses 30/8 — dot uses 30/3, so dot trails behind camera on reset.
    local lerpSpeed = isSpraying and 30 or (isRecovering and 8 or 3)
    dotSmoothP = Lerp(FT * lerpSpeed, dotSmoothP, targetP)
    dotSmoothY = Lerp(FT * lerpSpeed, dotSmoothY, targetY)

    -- Snap to zero when close enough
    if math.abs(dotSmoothP) < 0.005 then dotSmoothP = 0 end
    if math.abs(dotSmoothY) < 0.005 then dotSmoothY = 0 end

    weapon._dotSmoothP = dotSmoothP
    weapon._dotSmoothY = dotSmoothY

    local shootPos = owner:GetShootPos()
    local eyeAng = owner:EyeAngles()
    local bulletAngles = Angle(eyeAng.p + dotSmoothP, eyeAng.y + dotSmoothY, 0)
    local bulletForward = bulletAngles:Forward()
    local trace = util.TraceLine({
        start = shootPos,
        endpos = shootPos + bulletForward * 16384,
        filter = owner,
        mask = MASK_SHOT,
    })
    local screenPos = (trace.HitPos or (shootPos + bulletForward * 16384)):ToScreen()
    if not screenPos.visible then
        return
    end
    local dotX = screenPos.x
    local dotY = screenPos.y

    -- Green dot only.
    surface.SetDrawColor(0, 0, 0, 200)
    surface.DrawRect(dotX - 3, dotY - 3, 7, 7)
    surface.SetDrawColor(90, 255, 140, 235)
    surface.DrawRect(dotX - 2, dotY - 2, 5, 5)
end

function EDITOR.GetPattern(weaponOrClass)
    local className = weaponOrClass

    if type(weaponOrClass) ~= "string" then
        className = getWeaponClass(weaponOrClass)
    end

    if not className then
        return nil
    end

    local pattern = EDITOR.Patterns[className]
    if FAS2_CS2SprayResetLock and pattern and not EDITOR.IsTrustedNativePattern(pattern) then
        return nil
    end

    return pattern
end

function EDITOR.SerializePatterns()
    return util.TableToJSON(EDITOR.Patterns, true) or "{}"
end

function EDITOR.GetWeaponDefinition(weaponOrClass)
    local className = weaponOrClass

    if type(weaponOrClass) ~= "string" then
        className = getWeaponClass(weaponOrClass)
    end

    if not className then
        return nil, nil
    end

    return weapons.GetStored(className), className
end

function EDITOR.GetClipSizeForClass(className)
    local weaponDefinition = weapons.GetStored(className)
    if not weaponDefinition then
        return 0
    end

    if weaponDefinition.Primary then
        return math.max(math.floor(tonumber(weaponDefinition.Primary.ClipSize) or 0), 0)
    end

    return 0
end

local function getLargestRoundCountFromText(...)
    local best = 0

    for _, value in ipairs({...}) do
        if value ~= nil then
            local valueType = type(value)

            if valueType == "string" or valueType == "number" then
                for roundCount in string.gmatch(string.lower(tostring(value)), "(%d+)") do
                    best = math.max(best, tonumber(roundCount) or 0)
                end
            elseif valueType == "table" then
                for _, nestedValue in pairs(value) do
                    if type(nestedValue) == "table" and nestedValue.t then
                        best = math.max(best, getLargestRoundCountFromText(nestedValue.t))
                    elseif type(nestedValue) == "string" or type(nestedValue) == "number" then
                        best = math.max(best, getLargestRoundCountFromText(nestedValue))
                    end
                end
            end
        end
    end

    return best
end

function EDITOR.GetCalibrationClipSize(weapon)
    local clipSize = EDITOR.GetClipSize(weapon)

    if not IsValid(weapon) or type(weapon.Attachments) ~= "table" then
        return clipSize
    end

    for _, attachmentGroup in pairs(weapon.Attachments) do
        if type(attachmentGroup) == "table" and type(attachmentGroup.atts) == "table" then
            local isMagazineGroup = string.lower(tostring(attachmentGroup.header or "")) == "magazine"

            for _, attachmentKey in ipairs(attachmentGroup.atts) do
                local keyText = string.lower(tostring(attachmentKey or ""))
                if isMagazineGroup or string.find(keyText, "mag", 1, true) then
                    local attachmentData = FAS2_Attachments and FAS2_Attachments[attachmentKey] or nil
                    local candidateClipSize = getLargestRoundCountFromText(
                        attachmentKey,
                        attachmentData and attachmentData.nameshort,
                        attachmentData and attachmentData.namefull,
                        attachmentData and attachmentData.namemenu,
                        attachmentData and attachmentData.desc
                    )

                    clipSize = math.max(clipSize, candidateClipSize)
                end
            end
        end
    end

    return math.floor(math.max(clipSize, 0))
end

function EDITOR.GetCalibrationShotCapacity(weapon)
    local clipSize = EDITOR.GetCalibrationClipSize(weapon)
    if clipSize <= 0 then
        return 0
    end

    local chamberBonus = weapon and weapon.CantChamber and 0 or 1
    return math.floor(math.max(clipSize + chamberBonus, 0))
end

function EDITOR.GetDefaultSeedSourceClass(targetClass)
    local preferredSources = {
        "fas2_ak47",
        "fas2_ak74",
        "fas2_m4a1",
        "fas2_mp5a5",
    }

    for _, className in ipairs(preferredSources) do
        if className ~= targetClass and EDITOR.Patterns[className] then
            return className
        end
    end

    for className in pairs(EDITOR.Patterns) do
        if className ~= targetClass then
            return className
        end
    end

    return nil
end

function EDITOR.GetInterpolatedPoint(points, pointIndex)
    if type(points) ~= "table" or #points == 0 then
        return {p = 0, y = 0}
    end

    if pointIndex <= 1 then
        return {
            p = tonumber(points[1].p) or 0,
            y = tonumber(points[1].y) or 0,
        }
    end

    if pointIndex >= #points then
        return {
            p = tonumber(points[#points].p) or 0,
            y = tonumber(points[#points].y) or 0,
        }
    end

    local lowerIndex = math.floor(pointIndex)
    local upperIndex = math.ceil(pointIndex)
    local fraction = pointIndex - lowerIndex
    local lowerPoint = points[lowerIndex] or points[1]
    local upperPoint = points[upperIndex] or points[#points]

    return {
        p = Lerp(fraction, tonumber(lowerPoint.p) or 0, tonumber(upperPoint.p) or 0),
        y = Lerp(fraction, tonumber(lowerPoint.y) or 0, tonumber(upperPoint.y) or 0),
    }
end

function EDITOR.BuildSeedPattern(sourceClass, targetWeapon, manualScale)
    local sourcePattern = EDITOR.GetPattern(sourceClass)
    if type(sourcePattern) ~= "table" or type(sourcePattern.points) ~= "table" or #sourcePattern.points < 2 then
        return nil, "Source pattern not found: " .. tostring(sourceClass)
    end

    if not EDITOR.IsSupportedWeapon(targetWeapon) then
        return nil, "Equip a supported FA:S 2 weapon first."
    end

    local targetClass = getWeaponClass(targetWeapon)
    if not targetClass then
        return nil, "Target weapon class could not be resolved."
    end

    local targetClipSize = EDITOR.GetClipSize(targetWeapon)
    if targetClipSize <= 1 then
        targetClipSize = EDITOR.GetClipSizeForClass(targetClass)
    end

    if targetClipSize <= 1 then
        return nil, "Target weapon needs at least a 2-round clip size."
    end

    local sourceDefinition = weapons.GetStored(sourceClass) or {}
    local targetDefinition = weapons.GetStored(targetClass) or targetWeapon
    local sourceRecoil = tonumber(sourceDefinition.Recoil) or 1
    local targetRecoil = tonumber(targetDefinition.Recoil) or sourceRecoil
    local sourceViewKick = tonumber(sourceDefinition.ViewKick) or 1
    local targetViewKick = tonumber(targetDefinition.ViewKick) or sourceViewKick
    local sourceFireDelay = tonumber(sourceDefinition.FireDelay) or tonumber(sourcePattern.meta and sourcePattern.meta.fireDelay) or 0.1
    local targetFireDelay = tonumber(targetDefinition.FireDelay) or 0.1
    local scale = tonumber(manualScale)

    if not scale then
        local recoilScale = targetRecoil / math.max(sourceRecoil, 0.001)
        local kickScale = targetViewKick / math.max(sourceViewKick, 0.001)
        scale = math.Clamp((recoilScale * 0.7) + (kickScale * 0.3), 0.35, 2.75)
    end

    local seededPoints = {}
    local sourcePointCount = #sourcePattern.points

    for pointNumber = 1, targetClipSize do
        local sourcePosition = 1

        if targetClipSize > 1 then
            sourcePosition = 1 + ((pointNumber - 1) / (targetClipSize - 1)) * (sourcePointCount - 1)
        end

        local sourcePoint = EDITOR.GetInterpolatedPoint(sourcePattern.points, sourcePosition)
        seededPoints[pointNumber] = {
            p = (sourcePoint.p or 0) * scale,
            y = normalizeAngle((sourcePoint.y or 0) * scale),
        }
    end

    return {
        version = 1,
        weaponClass = targetClass,
        points = seededPoints,
        meta = {
            shotCount = targetClipSize,
            wallDistance = tonumber(sourcePattern.meta and sourcePattern.meta.wallDistance) or 0,
            resetDelay = math.max(targetFireDelay * 2.6, 0.18),
            adsMultiplier = 1,
            hipMultiplier = 1,
            seededFrom = sourceClass,
            seedScale = scale,
            fireDelay = targetFireDelay,
            sourceFireDelay = sourceFireDelay,
        },
    }
end

function EDITOR.LoadPatternsFromJSON(jsonText)
    local decoded = util.JSONToTable(jsonText or "{}")
    if type(decoded) ~= "table" then
        decoded = {}
    end

    for className, pattern in pairs(decoded) do
        if type(pattern) ~= "table" or type(pattern.points) ~= "table" then
            decoded[className] = nil
        end
    end

    local previous = EDITOR.Patterns or {}
    EDITOR.Patterns = decoded
    if FAS2_InstallCS2SprayReset then
        for className in pairs(previous) do
            if decoded[className] == nil then
                FAS2_InstallCS2SprayReset(false, className)
            end
        end
    end
    EDITOR.InstallNativeSprayPatterns()
end

function EDITOR.IsTrustedNativePattern(pattern)
    local meta = type(pattern) == "table" and pattern.meta or nil
    return type(meta) == "table" and meta.editorVersion == EDITOR.EditorVersion
end

function EDITOR.InstallNativePattern(className, pattern, force)
    if not className or className == "" then
        return false
    end

    if type(pattern) ~= "table" or type(pattern.points) ~= "table" or #pattern.points <= 0 then
        return false
    end

    if FAS2_CS2SprayResetLock and not force and not EDITOR.IsTrustedNativePattern(pattern) then
        return false
    end

    if not FAS2_SprayPatterns then
        FAS2_SprayPatterns = {}
    end

    -- GetSprayOffset multiplies by RecoilScale, so divide it out here
    -- so the final offset matches our recorded angles exactly.
    local recoilScale = FAS2_RecoilScale and FAS2_RecoilScale[className] or 1
    if recoilScale == 0 then recoilScale = 1 end
    local invScale = 1 / recoilScale

    -- Optional sign flip when a legacy pattern was recorded with the
    -- opposite pitch convention from FA:S base.
    local pitchSign = (FAS2_PatternInvertPitch and FAS2_PatternInvertPitch[className]) and -1 or 1

    local nativePat = {}
    for i, point in ipairs(pattern.points) do
        nativePat[i] = {
            (tonumber(point.p) or 0) * invScale * pitchSign,
            (tonumber(point.y) or 0) * invScale,
        }
    end

    FAS2_SprayPatterns[className] = nativePat

    local resetDelay = nil
    if pattern.meta and tonumber(pattern.meta.resetDelay) then
        resetDelay = math.max(tonumber(pattern.meta.resetDelay), 0.1)
    else
        local weaponDef = weapons.GetStored(className)
        local fireDelay = weaponDef and tonumber(weaponDef.FireDelay) or 0.1
        resetDelay = math.max(fireDelay * 2.6, 0.18)
    end

    if not FAS2_SprayResetTime then
        FAS2_SprayResetTime = {}
    end
    FAS2_SprayResetTime[className] = resetDelay

    local stored = weapons.GetStored(className)
    if stored then
        stored.SprayPattern = nativePat
        stored.SprayResetTime = resetDelay
    end

    for _, ply in ipairs(player.GetAll()) do
        local weapon = ply:GetActiveWeapon()
        if IsValid(weapon) and getWeaponClass(weapon) == className then
            weapon.SprayPattern = nativePat
            weapon.SprayResetTime = resetDelay
            weapon._sprayDataLoaded = nil
        end
    end

    return true
end

-- Convert pattern editor patterns into the native FAS2_SprayPatterns format
-- so that GetSprayDirection/GetSprayOffset/HipRecoil all work naturally.
-- This is the key integration: bullets, camera, and recovery all use ONE system.
function EDITOR.InstallNativeSprayPatterns()
    if not FAS2_SprayPatterns then
        FAS2_SprayPatterns = {}
    end

    for className, pattern in pairs(EDITOR.Patterns) do
        EDITOR.InstallNativePattern(className, pattern, false)
    end
end

function EDITOR.UnitsToMeters(distanceUnits)
    return (tonumber(distanceUnits) or 0) / 39.37
end

local function appendAmmoDescriptor(parts, value)
    if value == nil then
        return
    end

    local valueType = type(value)
    if valueType == "string" or valueType == "number" or valueType == "boolean" then
        local text = string.Trim(string.lower(tostring(value)))
        if text ~= "" then
            parts[#parts + 1] = text
        end
        return
    end

    if valueType ~= "table" then
        return
    end

    for key, nestedValue in pairs(value) do
        if type(nestedValue) == "string" or type(nestedValue) == "number" or type(nestedValue) == "boolean" then
            appendAmmoDescriptor(parts, key)
            appendAmmoDescriptor(parts, nestedValue)
        elseif type(nestedValue) == "table" then
            appendAmmoDescriptor(parts, key)

            if nestedValue.name then
                appendAmmoDescriptor(parts, nestedValue.name)
            end

            if nestedValue.displayName then
                appendAmmoDescriptor(parts, nestedValue.displayName)
            end

            if nestedValue.PrintName then
                appendAmmoDescriptor(parts, nestedValue.PrintName)
            end
        end
    end
end

function EDITOR.GetAmmoProfile(weapon)
    if not IsValid(weapon) then
        return {
            name = "standard",
            multiplier = 1,
        }
    end

    local parts = {}
    appendAmmoDescriptor(parts, getWeaponClass(weapon))
    appendAmmoDescriptor(parts, weapon.PrintName)
    appendAmmoDescriptor(parts, weapon.Primary and weapon.Primary.Ammo)
    appendAmmoDescriptor(parts, weapon.AmmoType)
    appendAmmoDescriptor(parts, weapon.AmmoName)
    appendAmmoDescriptor(parts, weapon.ActiveAttachments)
    appendAmmoDescriptor(parts, weapon.Attachments)

    if weapon.GetPrimaryAmmoType and game.GetAmmoName then
        local ammoType = weapon:GetPrimaryAmmoType()
        if ammoType and ammoType >= 0 then
            appendAmmoDescriptor(parts, game.GetAmmoName(ammoType))
        end
    end

    local descriptor = table.concat(parts, " ")

    if string.find(descriptor, "high velocity", 1, true) or string.find(descriptor, "%f[%a]hv%f[%A]") then
        return {
            name = "hv",
            multiplier = 1.2,
        }
    end

    if string.find(descriptor, "explosive", 1, true)
        or string.find(descriptor, "incendiary", 1, true)
        or string.find(descriptor, "flame", 1, true)
        or string.find(descriptor, "dragon", 1, true)
        or string.find(descriptor, "napalm", 1, true)
        or string.find(descriptor, "thermite", 1, true) then
        return {
            name = "volatile",
            multiplier = 0.78,
        }
    end

    return {
        name = "standard",
        multiplier = 1,
    }
end

function EDITOR.GetTargetDistance(weapon, cacheWindow)
    if not IsValid(weapon) then
        return nil, false
    end

    local owner = weapon.Owner or weapon:GetOwner()
    if not IsValid(owner) then
        return nil, false
    end

    local currentTime = CurTime()
    cacheWindow = tonumber(cacheWindow) or 0.05

    if weapon.FAS2SweetSpotTraceCache and (weapon.FAS2SweetSpotTraceCache.time or 0) + cacheWindow >= currentTime then
        local cached = weapon.FAS2SweetSpotTraceCache
        return cached.distanceUnits, cached.hit
    end

    local startPos = owner:GetShootPos()
    local trace = util.TraceLine({
        start = startPos,
        endpos = startPos + owner:GetAimVector() * 120000,
        filter = owner,
        mask = MASK_SHOT,
    })

    local distanceUnits = trace.Hit and startPos:Distance(trace.HitPos) or nil
    weapon.FAS2SweetSpotTraceCache = {
        time = currentTime,
        distanceUnits = distanceUnits,
        hit = trace.Hit == true,
    }

    return distanceUnits, trace.Hit == true
end

function EDITOR.GetSweetSpotData(weapon)
    if not IsValid(weapon) then
        return nil
    end

    local currentTime = CurTime()
    if weapon.FAS2SweetSpotCache and (weapon.FAS2SweetSpotCache.cachedAt or 0) + 0.05 >= currentTime then
        return weapon.FAS2SweetSpotCache
    end

    local pattern = EDITOR.GetPattern(weapon)
    local meta = pattern and pattern.meta or nil
    local baseDistanceUnits = tonumber(meta and (meta.sweetSpotDistance or meta.wallDistance)) or 0
    if baseDistanceUnits <= 0 then
        weapon.FAS2SweetSpotCache = nil
        return nil
    end

    local ammoProfile = EDITOR.GetAmmoProfile(weapon)
    local sweetSpotUnits = math.max(baseDistanceUnits * (tonumber(ammoProfile.multiplier) or 1), 1)
    local targetDistanceUnits, hasTraceHit = EDITOR.GetTargetDistance(weapon, 0.05)
    local effectiveDistanceUnits = targetDistanceUnits or sweetSpotUnits
    local ratio = math.max(effectiveDistanceUnits / sweetSpotUnits, 0)
    local spreadMultiplier = 1
    local status = "OPTIMAL"

    if ratio <= 1 then
        spreadMultiplier = Lerp(math.Clamp(ratio, 0, 1), 0.93, 0.82)
        status = ratio >= 0.85 and "OPTIMAL" or "CLOSE"
    elseif ratio <= 1.35 then
        spreadMultiplier = Lerp((ratio - 1) / 0.35, 0.82, 1)
        status = "STRETCH"
    else
        spreadMultiplier = Lerp(math.Clamp((ratio - 1.35) / 0.9, 0, 1), 1, 1.55)
        status = "FALLOFF"
    end

    local sweetSpotData = {
        cachedAt = currentTime,
        ammoName = ammoProfile.name,
        ammoMultiplier = tonumber(ammoProfile.multiplier) or 1,
        baseDistanceUnits = baseDistanceUnits,
        sweetSpotUnits = sweetSpotUnits,
        sweetSpotMeters = EDITOR.UnitsToMeters(sweetSpotUnits),
        targetDistanceUnits = targetDistanceUnits,
        targetDistanceMeters = targetDistanceUnits and EDITOR.UnitsToMeters(targetDistanceUnits) or nil,
        spreadMultiplier = spreadMultiplier,
        status = status,
        hasTraceHit = hasTraceHit,
    }

    weapon.FAS2SweetSpotCache = sweetSpotData
    return sweetSpotData
end

function EDITOR.GetResetDelay(weapon, pattern)
    local meta = pattern and pattern.meta or nil
    if meta and tonumber(meta.resetDelay) then
        return math.max(tonumber(meta.resetDelay) or 0, 0.1)
    end

    local fireDelay = IsValid(weapon) and tonumber(weapon.FireDelay) or 0.1
    return math.max(fireDelay * 2.6, 0.18)
end

function EDITOR.GetStepDelta(weapon, pattern)
    if not IsValid(weapon) or type(pattern) ~= "table" or type(pattern.points) ~= "table" then
        return nil
    end

    local pointCount = #pattern.points
    if pointCount < 1 then
        return nil
    end

    local currentTime = CurTime()
    local resetDelay = EDITOR.GetResetDelay(weapon, pattern)

    if (weapon.FAS2PatternLastShotTime or 0) + resetDelay < currentTime then
        weapon.FAS2PatternShotCount = 0
        weapon.FAS2PatternAccumulated = nil
    end

    local prevIndex = weapon.FAS2PatternShotCount or 0
    local currentIndex = math.min(prevIndex + 1, pointCount)
    local currentPoint = pattern.points[currentIndex]
    local prevPoint = prevIndex > 0 and pattern.points[prevIndex] or nil
    local prevP = prevPoint and (tonumber(prevPoint.p) or 0) or 0
    local prevY = prevPoint and (tonumber(prevPoint.y) or 0) or 0

    weapon.FAS2PatternShotCount = currentIndex
    weapon.FAS2PatternCurrentPointIndex = currentIndex
    weapon.FAS2PatternLastShotTime = currentTime

    return {
        p = (tonumber(currentPoint.p) or 0) - prevP,
        y = normalizeAngle((tonumber(currentPoint.y) or 0) - prevY),
    }
end

function EDITOR.ShouldUseCustomRecoil(weapon)
    -- Legacy playback manually pushed view angles and could drift out of sync
    -- with the real FA:S bullet path. Editor patterns now install into the
    -- native FAS2_SprayPatterns table, so test/save uses the exact same path
    -- as normal gameplay.
    return false
end

function EDITOR.ShouldUseLaserCalibration(weapon)
    if not IsValid(weapon) or not EDITOR.IsSupportedWeapon(weapon) then
        return false
    end

    local owner = weapon.Owner or weapon:GetOwner()
    if not IsValid(owner) then
        return false
    end

    if CLIENT and owner ~= LocalPlayer() then
        return false
    end

    if SERVER then
        local steamId64 = owner.SteamID64 and owner:SteamID64() or nil
        local session = steamId64 and EDITOR.ActivePainters[steamId64] or nil
        return session ~= nil and (session.phase == "capture" or session.phase == "countdown")
    end

    return EDITOR.ClientState and EDITOR.ClientState.active and not EDITOR.ClientState.reviewMode and not EDITOR.ClientState.testMode
end

function EDITOR.ResetLaserCalibrationState(weapon)
    if not IsValid(weapon) then
        return
    end

    local owner = weapon.Owner or weapon:GetOwner()
    if not IsValid(owner) then
        return
    end

    if owner.SetPunchAngle then
        owner:SetPunchAngle(Angle(0, 0, 0))
    end

    owner.ViewAff = 0
    weapon.AddSpread = 0
    weapon.AddSpreadSpeed = 1
    weapon.CurCone = 0
    weapon.ClumpSpread = 0
end

function EDITOR.GetLaserCalibrationAimAngles(weapon)
    if not IsValid(weapon) then
        return nil
    end

    local owner = weapon.Owner or weapon:GetOwner()
    if not IsValid(owner) then
        return nil
    end

    if SERVER then
        local steamId64 = owner.SteamID64 and owner:SteamID64() or nil
        local session = steamId64 and EDITOR.ActivePainters[steamId64] or nil
        if session and isangle(session.calibrationViewAngles) then
            return Angle(session.calibrationViewAngles.p, session.calibrationViewAngles.y, 0)
        end
    elseif CLIENT and EDITOR.ClientState and isangle(EDITOR.ClientState.calibrationViewAngles) then
        return Angle(EDITOR.ClientState.calibrationViewAngles.p, EDITOR.ClientState.calibrationViewAngles.y, 0)
    end

    local eyeAngles = owner:EyeAngles()
    return Angle(eyeAngles.p, eyeAngles.y, 0)
end

function EDITOR.FireLaserCalibrationBullet(weapon)
    if not IsValid(weapon) then
        return false
    end

    local owner = weapon.Owner or weapon:GetOwner()
    if not IsValid(owner) then
        return false
    end

    EDITOR.ResetLaserCalibrationState(weapon)

    local calibrationAngles = EDITOR.GetLaserCalibrationAimAngles(weapon)
    local direction = (calibrationAngles or owner:EyeAngles()):Forward()
    local bullet = {
        Num = math.max(tonumber(weapon.Shots) or 1, 1),
        Src = owner:GetShootPos(),
        Dir = direction,
        Spread = vector_origin,
        Tracer = 0,
        Force = (tonumber(weapon.Damage) or 1) * 0.1,
        Damage = math.Round(tonumber(weapon.Damage) or 1),
        Callback = function(_, traceResult)
            if IsValid(owner) and owner.SetEyeAngles and calibrationAngles then
                owner:SetEyeAngles(calibrationAngles)
            end

            return { effects = false }
        end,
    }

    -- Force eye angles to calibration angle BEFORE firing so any FA:S
    -- internal callbacks that read EyeAngles() get the locked value
    if calibrationAngles and SERVER then
        owner:SetEyeAngles(calibrationAngles)
    end

    owner:FireBullets(bullet)

    -- Force eye angles back AFTER firing in case FireBullets or its
    -- callbacks mutated them (recoil, viewpunch, etc.)
    if calibrationAngles and SERVER then
        owner:SetEyeAngles(calibrationAngles)
    end

    return true
end

function EDITOR.FreezeLaserViewmodelState(weapon)
    if not IsValid(weapon) then
        return
    end

    local owner = weapon.Owner or weapon:GetOwner()
    if not IsValid(owner) then
        return
    end

    weapon.AngleDelta = Angle(0, 0, 0)
    weapon.AngleDelta2 = Angle(0, 0, 0)
    weapon.OldDelta = Angle(owner:EyeAngles().p, owner:EyeAngles().y, 0)
    weapon.BlendPos = Vector(0, 0, 0)
    weapon.BlendAng = Vector(0, 0, 0)
    weapon.NadeBlendPos = Vector(0, 0, 0)
    weapon.NadeBlendAng = Vector(0, 0, 0)
    weapon.BipodPos = Vector(0, 0, 0)
    weapon.BipodAng = Vector(0, 0, 0)
    weapon.CurFOVMod = 0
end

function EDITOR.ApplyPatternRecoil(weapon, isAiming, mul)
    if not EDITOR.ShouldUseCustomRecoil(weapon) then
        return false
    end

    local owner = weapon.Owner or weapon:GetOwner()
    if not IsValid(owner) then
        return false
    end

    -- Detect test mode
    local inTestMode = false
    if CLIENT and EDITOR.ClientState and EDITOR.ClientState.active and EDITOR.ClientState.testMode then
        inTestMode = true
    elseif SERVER then
        local steamId64 = owner.SteamID64 and owner:SteamID64() or nil
        local session = steamId64 and EDITOR.ActivePainters[steamId64] or nil
        if session and session.phase == "test" then
            inTestMode = true
        end
    end

    if inTestMode then
        -- Test: pattern was already stepped in FireBullet. Lock the view
        -- to the target and zero PunchAngle so no bounce accumulates.
        if isangle(weapon.FAS2PatternTargetAngles) then
            owner:SetEyeAngles(Angle(weapon.FAS2PatternTargetAngles.p, weapon.FAS2PatternTargetAngles.y, 0))
        end
        if owner.SetPunchAngle then
            owner:SetPunchAngle(Angle(0, 0, 0))
        end
        -- Also zero the base weapon's custom camera systems so CalcView
        -- doesn't add offsets on top of the locked EyeAngles.
        if CLIENT then
            weapon._punchAng = Angle(0, 0, 0)
            weapon._punchVel = Angle(0, 0, 0)
            weapon._camAccP = 0
            weapon._camAccY = 0
            weapon._smoothCamP = 0
            weapon._smoothCamY = 0
        end
        return true
    end

    -- NORMAL MODE: Fall through to native HipRecoil/AimRecoil.
    -- Patterns are installed into FAS2_SprayPatterns by InstallNativeSprayPatterns(),
    -- so the native system handles everything:
    --   - Bullet direction via GetSprayDirection (uses GetSprayOffset + PatternIndex)
    --   - Camera bounce via _punchVel (spring-damper in CalcView)
    --   - Permanent camera shift via _camAccP/Y (auto-decays when not spraying)
    --   - Recovery/spring-back handled by CalcView decay loop

    -- Returning false lets the patched HipRecoil/AimRecoil call the original.
    -- CalcView's decay handles the spring-back naturally.
    return false
end

function EDITOR.PatchFAS2Base()
    local baseWeapon = weapons.GetStored("fas2_base")
    if not baseWeapon or baseWeapon.FAS2PatternEditorPatched then
        return baseWeapon ~= nil
    end

    baseWeapon.FAS2PatternEditorPatched = true

    local originalAimRecoil = baseWeapon.AimRecoil
    local originalHipRecoil = baseWeapon.HipRecoil
    local originalCalculateSpread = baseWeapon.CalculateSpread
    local originalCalcView = baseWeapon.CalcView
    local originalFireBullet = baseWeapon.FireBullet
    local originalDrawHUD = baseWeapon.DrawHUD
    local originalPostDrawViewModel = baseWeapon.PostDrawViewModel
    local originalReload = baseWeapon.Reload
    local originalDeploy = baseWeapon.Deploy
    local originalHolster = baseWeapon.Holster

    function baseWeapon:AimRecoil(mul)
        if EDITOR.ShouldUseLaserCalibration(self) then
            EDITOR.ResetLaserCalibrationState(self)
            return
        end

        if EDITOR.ApplyPatternRecoil(self, true, mul) then
            return
        end

        return originalAimRecoil(self, mul)
    end

    function baseWeapon:HipRecoil(mul)
        if EDITOR.ShouldUseLaserCalibration(self) then
            EDITOR.ResetLaserCalibrationState(self)
            return
        end

        if EDITOR.ApplyPatternRecoil(self, false, mul) then
            return
        end

        return originalHipRecoil(self, mul)
    end

    function baseWeapon:CalculateSpread(...)
        local result = originalCalculateSpread(self, ...)

        if EDITOR.ShouldUseLaserCalibration(self) then
            EDITOR.ResetLaserCalibrationState(self)
            self.FAS2SweetSpot = nil
            return result
        end

        if EDITOR.ShouldUseCustomRecoil(self) then
            self.FAS2SweetSpot = nil
            return result
        end

        if self.dt and self.dt.Status == FAS_STAT_ADS then
            local sweetSpotData = EDITOR.GetSweetSpotData(self)
            if sweetSpotData then
                self.CurCone = math.Clamp((self.CurCone or self.AimCone or 0) * sweetSpotData.spreadMultiplier, 0, 0.09 + (self.MaxSpreadInc or 0))
                self.FAS2SweetSpot = sweetSpotData
            else
                self.FAS2SweetSpot = nil
            end
        else
            self.FAS2SweetSpot = nil
        end

        return result
    end

    function baseWeapon:CalcView(ply, pos, ang, fov)
        if EDITOR.ShouldUseLaserCalibration(self) then
            self.CurFOVMod = 0
            return pos, ang, fov or GetConVarNumber("fov_desired")
        end

        return originalCalcView(self, ply, pos, ang, fov)
    end

    function baseWeapon:FireBullet(...)
        if EDITOR.ShouldUseLaserCalibration(self) then
            -- Calibration: fire bullets STRAIGHT where the player is looking.
            -- Zero spread, zero recoil, bypass weapon's own spray system.
            -- The player draws the pattern by moving their mouse.
            local owner = self.Owner or self:GetOwner()
            if not IsValid(owner) then
                return
            end

            if owner.SetPunchAngle then
                owner:SetPunchAngle(Angle(0, 0, 0))
            end

            local bullet = {
                Num = math.max(tonumber(self.Shots) or 1, 1),
                Src = owner:GetShootPos(),
                Dir = owner:EyeAngles():Forward(),
                Spread = vector_origin,
                Tracer = 4,
                Force = (tonumber(self.Damage) or 1) * 0.1,
                Damage = math.Round(tonumber(self.Damage) or 1),
            }
            owner:FireBullets(bullet)

            if owner.SetPunchAngle then
                owner:SetPunchAngle(Angle(0, 0, 0))
            end

            return
        end

        if EDITOR.ShouldUseCustomRecoil(self) then
            -- Detect test mode
            local owner = self.Owner or self:GetOwner()
            local inTestMode = false
            if IsValid(owner) then
                if CLIENT and EDITOR.ClientState and EDITOR.ClientState.active and EDITOR.ClientState.testMode and EDITOR.ClientState.pendingPayload and EDITOR.ClientState.pendingPayload.weaponClass == getWeaponClass(self) then
                    inTestMode = true
                elseif SERVER then
                    local steamId64 = owner.SteamID64 and owner:SteamID64() or nil
                    local session = steamId64 and EDITOR.ActivePainters[steamId64] or nil
                    if session and session.phase == "test" then
                        inTestMode = true
                    end
                end
            end

            if inTestMode and IsValid(owner) then
                -- TEST MODE: Step pattern BEFORE firing so the bullet and
                -- the EntityFireBullets hook both have the correct target.
                local pattern = nil
                if CLIENT and EDITOR.ClientState and EDITOR.ClientState.pendingPayload then
                    pattern = EDITOR.ClientState.pendingPayload
                elseif SERVER then
                    local steamId64 = owner.SteamID64 and owner:SteamID64() or nil
                    local session = steamId64 and EDITOR.ActivePainters[steamId64] or nil
                    if session and type(session.testPayload) == "table" then
                        pattern = session.testPayload
                    end
                end
                pattern = pattern or EDITOR.GetPattern(self)

                local delta = EDITOR.GetStepDelta(self, pattern)
                local isADS = self.dt and self.dt.Status == FAS_STAT_ADS
                if delta and not isADS then
                    local shotCount = self.FAS2PatternShotCount or 0
                    if shotCount <= 1 then
                        self.FAS2PatternBaseAngles = Angle(owner:EyeAngles().p, owner:EyeAngles().y, 0)
                    end
                    local baseAngles = self.FAS2PatternBaseAngles or Angle(0, 0, 0)
                    local pointIndex = math.min(tonumber(self.FAS2PatternCurrentPointIndex) or 0, type(pattern.points) == "table" and #pattern.points or 0)
                    local targetPoint = pointIndex > 0 and pattern.points[pointIndex] or nil
                    if type(targetPoint) == "table" then
                        self.FAS2PatternTargetAngles = Angle(
                            math.Clamp(baseAngles.p + (tonumber(targetPoint.p) or 0), -89, 89),
                            normalizeAngle(baseAngles.y + (tonumber(targetPoint.y) or 0)),
                            0
                        )
                        owner:SetEyeAngles(Angle(self.FAS2PatternTargetAngles.p, self.FAS2PatternTargetAngles.y, 0))
                    end
                end

                -- Zero PunchAngle so originalFireBullet fires at exactly
                -- EyeAngles (no stale ViewPunch residue corrupting aim).
                -- Skipped in ADS so iron-sight feel isn't disturbed by
                -- the test pass; in ADS the user just confirms feel.
                if not isADS and owner.SetPunchAngle then
                    owner:SetPunchAngle(Angle(0, 0, 0))
                end
                return originalFireBullet(self, ...)
            end

            -- NORMAL MODE: Fire normally. Bullets use EyeAngles + PunchAngle
            -- (same as AK). AimRecoil will shift EyeAngles AFTER this.
            return originalFireBullet(self, ...)
        end

        return originalFireBullet(self, ...)
    end

    function baseWeapon:DrawHUD(...)
        local result = nil

        if originalDrawHUD then
            result = originalDrawHUD(self, ...)
        end

        return result
    end

    function baseWeapon:PostDrawViewModel(...)
        if EDITOR.ShouldUseLaserCalibration(self) then
            EDITOR.FreezeLaserViewmodelState(self)

            if not originalPostDrawViewModel then
                return
            end

            local result = originalPostDrawViewModel(self, ...)

            EDITOR.FreezeLaserViewmodelState(self)
            return result
        end

        if not originalPostDrawViewModel then
            return
        end

        return originalPostDrawViewModel(self, ...)
    end

    function baseWeapon:Reload(...)
        EDITOR.ResetWeaponState(self)
        return originalReload(self, ...)
    end

    function baseWeapon:Deploy(...)
        EDITOR.ResetWeaponState(self)
        return originalDeploy(self, ...)
    end

    function baseWeapon:Holster(...)
        EDITOR.ResetWeaponState(self)
        return originalHolster(self, ...)
    end

    return true
end

local function patchWithRetry(attempt)
    attempt = attempt or 0

    if EDITOR.PatchFAS2Base() or attempt >= 20 then
        return
    end

    timer.Simple(0.25, function()
        patchWithRetry(attempt + 1)
    end)
end

patchWithRetry(0)

if SERVER then
    util.AddNetworkString("FAS2PatternEditor.Enter")
    util.AddNetworkString("FAS2PatternEditor.Exit")
    util.AddNetworkString("FAS2PatternEditor.RecordShot")
    util.AddNetworkString("FAS2PatternEditor.TestCountdown")
    util.AddNetworkString("FAS2PatternEditor.TestBegin")
    util.AddNetworkString("FAS2PatternEditor.TestPattern")
    util.AddNetworkString("FAS2PatternEditor.DebugMode")
    util.AddNetworkString("FAS2PatternEditor.Save")
    util.AddNetworkString("FAS2PatternEditor.Sync")
    util.AddNetworkString("FAS2PatternEditor.Clear")
    util.AddNetworkString("FAS2PatternEditor.Step")
    util.AddNetworkString("FAS2PatternEditor.Refill")

    local function loadPatterns()
        file.CreateDir(EDITOR.DataDir)

        if not file.Exists(EDITOR.DataFile, "DATA") then
            EDITOR.Patterns = {}
            return
        end

        EDITOR.LoadPatternsFromJSON(file.Read(EDITOR.DataFile, "DATA") or "{}")
    end

    local function savePatterns()
        file.CreateDir(EDITOR.DataDir)
        file.Write(EDITOR.DataFile, EDITOR.SerializePatterns())
    end

    local function syncPatterns(targetPlayer)
        net.Start("FAS2PatternEditor.Sync")
        net.WriteString(EDITOR.SerializePatterns())

        if IsValid(targetPlayer) then
            net.Send(targetPlayer)
        else
            net.Broadcast()
        end
    end

    local function getTestTimerName(player)
        return "FAS2PatternEditor.TestCountdown." .. tostring(IsValid(player) and player:SteamID64() or "0")
    end

    local function parseBooleanWord(value)
        value = string.lower(string.Trim(tostring(value or "")))
        if value == "1" or value == "true" or value == "on" or value == "yes" then
            return true
        end

        if value == "0" or value == "false" or value == "off" or value == "no" then
            return false
        end

        return nil
    end

    local allowedGroups = {
        owner = true,
        boss = true,
        founder = true,
        headadmin = true,
        superadmin = true,
        admin = true,
    }

    local function canEditPatterns(player)
        if game.SinglePlayer() then
            return true
        end

        if not IsValid(player) then
            return false
        end

        if player:IsListenServerHost() or player:IsSuperAdmin() or player:IsAdmin() then
            return true
        end

        local userGroup = player.GetUserGroup and string.lower(tostring(player:GetUserGroup() or "")) or ""
        return allowedGroups[userGroup] == true
    end

    local function refillPaintWeapon(player, weapon, clipSize)
        if not IsValid(player) or not IsValid(weapon) then
            return 0
        end

        local totalShots = math.floor(tonumber(clipSize) or EDITOR.GetCalibrationShotCapacity(weapon))
        if totalShots <= 0 then
            return 0
        end

        weapon:SetClip1(totalShots)

        local ammoType = weapon:GetPrimaryAmmoType()
        if ammoType and ammoType >= 0 then
            player:SetAmmo(math.max(player:GetAmmoCount(ammoType), totalShots * 6), ammoType)
        end

        EDITOR.ResetWeaponState(weapon)
        return totalShots
    end

    local function syncPaintWeaponStep(player, shotCount)
        if not IsValid(player) then
            return
        end

        local weapon = player:GetActiveWeapon()
        if not EDITOR.IsSupportedWeapon(weapon) then
            return
        end

        local totalShots = EDITOR.GetCalibrationShotCapacity(weapon)
        if totalShots <= 0 then
            return
        end

        local remaining = math.max(totalShots - math.max(tonumber(shotCount) or 0, 0), 0)
        weapon:SetClip1(remaining)
    end

    local function seedActiveWeapon(player, sourceClass, manualScale)
        if not canEditPatterns(player) then
            player:ChatPrint("[FAS2 Editor] Admin access required.")
            return false
        end

        local weapon = player:GetActiveWeapon()
        if not EDITOR.IsSupportedWeapon(weapon) then
            player:ChatPrint("[FAS2 Editor] Equip a FA:S 2 weapon first.")
            return false
        end

        local targetClass = getWeaponClass(weapon)
        sourceClass = sourceClass or EDITOR.GetDefaultSeedSourceClass(targetClass)

        if not sourceClass or sourceClass == "" then
            player:ChatPrint("[FAS2 Editor] No saved source spray exists yet. Paint the AK first.")
            return false
        end

        local payload, errorMessage = EDITOR.BuildSeedPattern(sourceClass, weapon, manualScale)
        if not payload then
            player:ChatPrint("[FAS2 Editor] " .. tostring(errorMessage))
            return false
        end

        payload.savedAt = os.date("%Y-%m-%d %H:%M:%S")
        payload.savedBy = IsValid(player) and player:Nick() or "server"
        payload.meta = type(payload.meta) == "table" and payload.meta or {}
        payload.meta.editorVersion = EDITOR.EditorVersion

        EDITOR.Patterns[payload.weaponClass] = payload
        EDITOR.InstallNativePattern(payload.weaponClass, payload, true)
        savePatterns()
        syncPatterns()

        player:ChatPrint(string.format("[FAS2 Editor] Seeded %s from %s at %.2fx. Use !faspattern to refine it.", payload.weaponClass, sourceClass, tonumber(payload.meta.seedScale) or 1))
        return true
    end

    local function restorePaintWeaponState(session, player)
        if type(session) ~= "table" then
            return
        end

        local weapon = IsValid(session.weaponEntity) and session.weaponEntity or (IsValid(player) and player:GetActiveWeapon() or nil)
        if IsValid(weapon) and session.originalFireMode and weapon.SelectFiremode then
            weapon:SelectFiremode(session.originalFireMode)
        end
        if IsValid(weapon) and session.originalPenetrationEnabled ~= nil then
            weapon.PenetrationEnabled = session.originalPenetrationEnabled
        end
        if IsValid(weapon) and session.originalRicochetEnabled ~= nil then
            weapon.RicochetEnabled = session.originalRicochetEnabled
        end
    end

    local function beginPaintMode(player)
        if not canEditPatterns(player) then
            player:ChatPrint("[FAS2 Editor] Admin access required.")
            return
        end

        local weapon = player:GetActiveWeapon()
        if not EDITOR.IsSupportedWeapon(weapon) then
            player:ChatPrint("[FAS2 Editor] Equip a FA:S 2 weapon first.")
            return
        end

        local totalShots = EDITOR.GetCalibrationShotCapacity(weapon)
        if totalShots <= 1 then
            player:ChatPrint("[FAS2 Editor] This weapon needs at least a 2-round pattern.")
            return
        end

        local originalFireMode = weapon.FireMode
        local switchedToSemi = false
        if weapon.SelectFiremode and type(weapon.FireModes) == "table" then
            for _, mode in ipairs(weapon.FireModes) do
                if mode == "semi" and weapon.FireMode ~= "semi" then
                    weapon:SelectFiremode("semi")
                    switchedToSemi = true
                    break
                end
            end
        end

        EDITOR.ActivePainters[player:SteamID64()] = {
            weaponClass = getWeaponClass(weapon),
            phase = "capture",
            shotCount = 0,
            maxShots = totalShots,
            weaponEntity = weapon,
            originalFireMode = originalFireMode,
            switchedToSemi = switchedToSemi,
            originalPenetrationEnabled = weapon.PenetrationEnabled,
            originalRicochetEnabled = weapon.RicochetEnabled,
            lastCommandNumber = nil,
            testPayload = nil,
            captureOriginPos = nil,
            captureOriginEyeAngles = nil,
        }
        weapon.PenetrationEnabled = false
        weapon.RicochetEnabled = false
        player:GodEnable()
        refillPaintWeapon(player, weapon, totalShots)

        net.Start("FAS2PatternEditor.Enter")
        net.WriteString(getWeaponClass(weapon) or "")
        net.WriteUInt(math.min(totalShots, 255), 8)
        net.WriteBool(EDITOR.GetPattern(weapon) ~= nil)
        net.Send(player)

        player:ChatPrint("[FAS2 Editor] Live pattern capture started for " .. (getWeaponClass(weapon) or "unknown"))
        player:ChatPrint(string.format("[FAS2 Editor] Calibration loaded %d rounds%s.", totalShots, weapon.CantChamber and "" or " including +1 in chamber"))
        player:ChatPrint("[FAS2 Editor] Move to the wall distance you want, then fire shot 1 to start calibration.")
        player:ChatPrint("[FAS2 Editor] After shot 1, stay still and fire one round at a time until the mag is empty. Moving resets and refills the capture.")
        if switchedToSemi then
            player:ChatPrint("[FAS2 Editor] Switched to semi-auto for clean one-shot capture. Comma still cycles firemode if you need it.")
        else
            player:ChatPrint("[FAS2 Editor] Use comma to cycle firemode if this weapon can shoot more than one round per tap.")
        end
        local scalePitch = tonumber(FAS2_CS2PatternScalePitch) or 1
        local scaleYaw = tonumber(FAS2_CS2PatternScaleYaw) or scalePitch
        player:ChatPrint(string.format("[FAS2 Editor] F5 test/retest, F6 save/review, F7 redo, F8 reset tuned default, F9 refill, ESC exits. Defaults: %.1fx pitch / %.1fx yaw.", scalePitch, scaleYaw))
    end

    local function exitPaintMode(player)
        local steamId64 = IsValid(player) and player:SteamID64() or nil
        local session = steamId64 and EDITOR.ActivePainters[steamId64] or nil
        if IsValid(player) then
            timer.Remove(getTestTimerName(player))
        end
        restorePaintWeaponState(session, player)
        if steamId64 then
            EDITOR.ActivePainters[steamId64] = nil
        end

        if IsValid(player) then
            player:GodDisable()
            net.Start("FAS2PatternEditor.Exit")
            net.Send(player)
        end
    end

    hook.Add("Initialize", "FAS2PatternEditor.LoadPatterns", loadPatterns)

    hook.Add("PlayerInitialSpawn", "FAS2PatternEditor.SyncOnJoin", function(player)
        timer.Simple(1, function()
            if IsValid(player) then
                syncPatterns(player)
            end
        end)
    end)

    hook.Add("PlayerDisconnected", "FAS2PatternEditor.Cleanup", function(player)
        local steamId64 = player:SteamID64()
        restorePaintWeaponState(EDITOR.ActivePainters[steamId64], player)
        EDITOR.ActivePainters[steamId64] = nil
    end)

    hook.Add("EntityFireBullets", "FAS2PatternEditor.RecordShot", function(entity, bulletData)
        if not IsValid(entity) or not entity:IsPlayer() then
            return
        end

        local steamId64 = entity:SteamID64()
        local session = EDITOR.ActivePainters[steamId64]
        if not session then
            return
        end

        local weapon = entity:GetActiveWeapon()
        if not EDITOR.IsSupportedWeapon(weapon) then
            return
        end

        local weaponClass = getWeaponClass(weapon)
        if weaponClass ~= session.weaponClass then
            return
        end

        if session.phase == "review" then
            return
        end

        local currentCommand = entity.GetCurrentCommand and entity:GetCurrentCommand() or nil
        local commandNumber = currentCommand and currentCommand.CommandNumber and currentCommand:CommandNumber() or nil
        if commandNumber and session.lastCommandNumber == commandNumber then
            return
        end

        session.lastCommandNumber = commandNumber or session.lastCommandNumber

        local modifiedBullet = false

        -- During calibration: force bullet to go along the exact raw aim
        -- line. During test, do not override anything; the pending pattern is
        -- installed into native FAS2_SprayPatterns so this records the real
        -- gameplay path.
        if session.phase == "capture" then
            local aimAngles = entity:EyeAngles()

            bulletData.Dir = aimAngles:Forward()
            bulletData.Spread = vector_origin
            bulletData.Num = 1
            modifiedBullet = true
        end

        session.shotCount = math.min((session.shotCount or 0) + 1, session.maxShots or 255)

        if session.phase == "capture" and session.shotCount == 1 then
            session.captureOriginPos = Vector(entity:GetPos())
            session.captureOriginEyeAngles = Angle(entity:EyeAngles().p, entity:EyeAngles().y, 0)
        end

        local startPos = bulletData.Src or entity:GetShootPos()
        local direction = bulletData.Dir or entity:GetAimVector()
        if not isvector(startPos) then
            startPos = entity:GetShootPos()
        end

        if not isvector(direction) or direction:LengthSqr() <= 0 then
            direction = entity:GetAimVector()
        else
            direction = direction:GetNormalized()
        end

        local trace = util.TraceLine({
            start = startPos,
            endpos = startPos + direction * 120000,
            filter = entity,
            mask = MASK_SHOT,
        })
        local hitDistance = startPos:Distance(trace.Hit and trace.HitPos or (startPos + direction * 120000))

        if session.phase == "capture" and session.shotCount == 1 then
            if hitDistance < EDITOR.MinCalibrationUnits or hitDistance > EDITOR.MaxCalibrationUnits then
                session.shotCount = 0
                session.lastCommandNumber = nil
                session.captureOriginPos = nil
                session.captureOriginEyeAngles = nil
                refillPaintWeapon(entity, weapon, session.maxShots)
                entity:ChatPrint(string.format("[FAS2 Editor] Use a flat wall around 20-35m. Current aim is %.1fm, so shot 1 was ignored.", EDITOR.UnitsToMeters(hitDistance)))
                return modifiedBullet or nil
            end
        end

        net.Start("FAS2PatternEditor.RecordShot")
        net.WriteVector(startPos)
        net.WriteVector(trace.Hit and trace.HitPos or (startPos + direction * 120000))
        net.WriteUInt(math.min(session.shotCount, 255), 8)
        net.WriteUInt(math.min(session.maxShots or 0, 255), 8)
        net.WriteBool(session.phase == "test")
        net.Send(entity)

        if session.phase == "capture" and session.shotCount >= (session.maxShots or 0) then
            session.phase = "captured"
        elseif session.phase == "test" and session.shotCount >= (session.maxShots or 0) then
            session.phase = "review"
        end

        -- Return true only when calibration changed bulletData.
        return modifiedBullet or nil
    end)

    hook.Add("PlayerSay", "FAS2PatternEditor.ChatCommands", function(player, text)
        local commandText = string.lower(string.Trim(text or ""))
        local words = splitWords(commandText)
        local command = words[1] or ""
            local subcommand = words[2] or ""

        if command == "!fasseed" or command == "/fasseed" then
            seedActiveWeapon(player, words[2], tonumber(words[3] or ""))
            return ""
        end

        if command == "!faspatterndebug" or command == "/faspatterndebug" then
            local enabled = parseBooleanWord(words[2])
            if enabled == nil then
                enabled = not player:GetNWBool("FAS2PatternEditorDebug", false)
            end

            player:SetNWBool("FAS2PatternEditorDebug", enabled)
            net.Start("FAS2PatternEditor.DebugMode")
            net.WriteBool(enabled)
            net.Send(player)
            player:ChatPrint("[FAS2 Editor] Pattern debug " .. (enabled and "enabled" or "disabled"))
            return ""
        end

        if not EDITOR.CommandAliases[command] then
            return
        end

        if subcommand == "reset" or subcommand == "default" or subcommand == "clear" then
            if not canEditPatterns(player) then
                player:ChatPrint("[FAS2 Editor] Admin access required.")
                return ""
            end

            local weapon = player:GetActiveWeapon()
            if not EDITOR.IsSupportedWeapon(weapon) then
                player:ChatPrint("[FAS2 Editor] Equip a FA:S 2 weapon first.")
                return ""
            end

            local className = getWeaponClass(weapon)
            if not className or className == "" then
                player:ChatPrint("[FAS2 Editor] Could not resolve the active weapon class.")
                return ""
            end

            EDITOR.Patterns[className] = nil
            if FAS2_InstallCS2SprayReset then
                FAS2_InstallCS2SprayReset(false, className)
            end
            savePatterns()
            syncPatterns()
            exitPaintMode(player)
            player:ChatPrint("[FAS2 Editor] Reset pattern to default for " .. className)
            return ""
        end

        beginPaintMode(player)
        return ""
    end)

    hook.Add("StartCommand", "FAS2PatternEditor.BlockAttackServer", function(player, cmd)
        if not IsValid(player) then
            return
        end

        local session = EDITOR.ActivePainters[player:SteamID64()]
        if not session then
            return
        end

        local buttons = cmd:GetButtons()
        buttons = bit.band(buttons, bit.bnot(IN_RELOAD))

        local activeWeapon = player:GetActiveWeapon()
        if EDITOR.ShouldUseLaserCalibration(activeWeapon) then
            EDITOR.ResetLaserCalibrationState(activeWeapon)
        end

        -- During capture: let the player freely move their mouse to draw the pattern.
        -- Recoil is already suppressed (HipRecoil/AimRecoil return early),
        -- so eye angles only change from genuine mouse input.
        if session.phase == "capture" and not isangle(session.calibrationViewAngles) and cmd.GetViewAngles then
            session.calibrationViewAngles = Angle(cmd:GetViewAngles().p, cmd:GetViewAngles().y, 0)
        end

        local movementLocked = session.phase ~= "review" and ((session.phase == "countdown") or (session.phase == "captured") or (session.phase == "test") or (session.shotCount or 0) > 0)
        if movementLocked then
            buttons = bit.band(buttons, bit.bnot(IN_FORWARD + IN_BACK + IN_MOVELEFT + IN_MOVERIGHT + IN_JUMP + IN_DUCK + IN_SPEED + IN_WALK))
            cmd:SetForwardMove(0)
            cmd:SetSideMove(0)
            cmd:SetUpMove(0)
        end

        cmd:SetButtons(buttons)
    end)

    concommand.Add("fas2_pattern_editor", function(player)
        if not IsValid(player) then
            return
        end

        beginPaintMode(player)
    end)

    concommand.Add("fas2_pattern_editor_exit", function(player)
        if not IsValid(player) then
            return
        end

        exitPaintMode(player)
    end)

    concommand.Add("fas2_pattern_editor_clear", function(player)
        if not IsValid(player) or not canEditPatterns(player) then
            return
        end

        local weapon = player:GetActiveWeapon()
        if not EDITOR.IsSupportedWeapon(weapon) then
            player:ChatPrint("[FAS2 Editor] Equip a FA:S 2 weapon first.")
            return
        end

        local className = getWeaponClass(weapon)
        EDITOR.Patterns[className] = nil
        savePatterns()
        syncPatterns()
        player:ChatPrint("[FAS2 Editor] Cleared pattern for " .. className)
    end)

    concommand.Add("fas2_pattern_editor_seed", function(player, _, args)
        if not IsValid(player) then
            return
        end

        local sourceClass = string.Trim(args[1] or "")
        if sourceClass == "" then
            sourceClass = nil
        end

        local manualScale = tonumber(args[2] or "")
        seedActiveWeapon(player, sourceClass, manualScale)
    end)

    net.Receive("FAS2PatternEditor.Save", function(_, player)
        if not canEditPatterns(player) then
            return
        end

        local weaponClass = net.ReadString()
        local jsonText = net.ReadString()
        local payload = util.JSONToTable(jsonText or "")

        if type(payload) ~= "table" or type(payload.points) ~= "table" or #payload.points < 2 then
            return
        end

        payload.weaponClass = weaponClass
        payload.meta = type(payload.meta) == "table" and payload.meta or {}
        payload.meta.editorVersion = EDITOR.EditorVersion
        if not tonumber(payload.meta.sweetSpotDistance) then
            local weapon = player:GetActiveWeapon()
            payload.meta.sweetSpotDistance = IsValid(weapon) and tonumber(weapon.EffectiveRange) or tonumber(payload.meta.wallDistance) or 0
        end
        payload.savedAt = os.date("%Y-%m-%d %H:%M:%S")
        payload.savedBy = IsValid(player) and player:Nick() or "server"

        EDITOR.Patterns[weaponClass] = payload
        EDITOR.InstallNativePattern(weaponClass, payload, true)
        savePatterns()
        syncPatterns()

        if IsValid(player) then
            player:ChatPrint("[FAS2 Editor] Saved pattern for " .. weaponClass)
        end

        -- Tap: lets the ballistics extension (or any other) auto-prompt
        -- after a successful pattern save. Safe no-op when no listeners.
        hook.Run("FAS2PatternEditor.PostSave", player, weaponClass)
    end)

    net.Receive("FAS2PatternEditor.Clear", function(_, player)
        if not canEditPatterns(player) then
            return
        end

        local weaponClass = net.ReadString()
        if not weaponClass or weaponClass == "" then
            return
        end

        EDITOR.Patterns[weaponClass] = nil
        if FAS2_InstallCS2SprayReset then
            FAS2_InstallCS2SprayReset(false, weaponClass)
        end
        savePatterns()
        syncPatterns()
    end)

    net.Receive("FAS2PatternEditor.Step", function(_, player)
        if not IsValid(player) then
            return
        end

        if not EDITOR.ActivePainters[player:SteamID64()] then
            return
        end

        syncPaintWeaponStep(player, net.ReadUInt(8))
    end)

    net.Receive("FAS2PatternEditor.Refill", function(_, player)
        if not IsValid(player) then
            return
        end

        local session = EDITOR.ActivePainters[player:SteamID64()]
        if not session then
            return
        end

        local weapon = player:GetActiveWeapon()
        if not EDITOR.IsSupportedWeapon(weapon) then
            return
        end

        session.shotCount = 0
        session.phase = "capture"
        session.testPayload = nil
        session.lastCommandNumber = nil
        session.calibrationViewAngles = Angle(player:EyeAngles().p, player:EyeAngles().y, 0)
        session.weaponEntity = weapon
        timer.Remove(getTestTimerName(player))

        EDITOR.ResetWeaponState(weapon)
        refillPaintWeapon(player, weapon, session.maxShots)
    end)

    net.Receive("FAS2PatternEditor.TestPattern", function(_, player)
        if not IsValid(player) then
            return
        end

        local session = EDITOR.ActivePainters[player:SteamID64()]
        if not session then
            return
        end

        local weaponClass = net.ReadString()
        local jsonText = net.ReadString()
        local payload = util.JSONToTable(jsonText or "")
        if type(payload) ~= "table" or type(payload.points) ~= "table" or #payload.points < 2 then
            return
        end

        local weapon = player:GetActiveWeapon()
        if not EDITOR.IsSupportedWeapon(weapon) then
            return
        end

        payload.weaponClass = weaponClass
        payload.meta = type(payload.meta) == "table" and payload.meta or {}
        payload.meta.editorVersion = EDITOR.EditorVersion
        EDITOR.InstallNativePattern(weaponClass, payload, true)
        session.phase = "countdown"
        session.testPayload = payload
        session.shotCount = 0
        session.lastCommandNumber = nil
        session.weaponEntity = weapon

        net.Start("FAS2PatternEditor.TestCountdown")
        net.WriteUInt(3, 3)
        net.Send(player)

        timer.Remove(getTestTimerName(player))
        timer.Create(getTestTimerName(player), 3, 1, function()
            if not IsValid(player) then
                return
            end

            local activeSession = EDITOR.ActivePainters[player:SteamID64()]
            if not activeSession or activeSession.phase ~= "countdown" then
                return
            end

            local activeWeapon = player:GetActiveWeapon()
            if not EDITOR.IsSupportedWeapon(activeWeapon) then
                return
            end

            activeSession.phase = "test"
            activeSession.shotCount = 0
            activeSession.lastCommandNumber = nil
            activeSession.calibrationViewAngles = nil
            activeSession.weaponEntity = activeWeapon

            if isvector(activeSession.captureOriginPos) then
                player:SetPos(activeSession.captureOriginPos)
                player:SetLocalVelocity(vector_origin)
            end

            if isangle(activeSession.captureOriginEyeAngles) then
                player:SetEyeAngles(activeSession.captureOriginEyeAngles)
            end

            EDITOR.ResetWeaponState(activeWeapon)
            refillPaintWeapon(player, activeWeapon, activeSession.maxShots)

            net.Start("FAS2PatternEditor.TestBegin")
            net.Send(player)
            player:ChatPrint("[FAS2 Editor] Test pass live. You have been reset to the original capture origin. Fire the full spray now.")
        end)
    end)

    loadPatterns()
    return
end

EDITOR.ClientState = EDITOR.ClientState or {
    active = false,
    preTestMode = false,
    reviewMode = false,
    testMode = false,
    testPending = false,
    testCountdownEnd = 0,
    weaponClass = nil,
    captureMode = nil,
    maxShots = 0,
    shots = {},
    testShots = {},
    trailPoints = {},
    referencePos = nil,
    testReferencePos = nil,
    wallDist = 0,
    hasExistingPattern = false,
    pendingPayload = nil,
    testSummary = nil,
    keyLatch = {},
    startPos = nil,
    calibrationViewAngles = nil,
    lastImpactTime = 0,
    decalClearAt = 0,
}

local STATE = EDITOR.ClientState
local exitPaintMode
EDITOR.DebugEnabled = EDITOR.DebugEnabled == true
local IMPACT_FADE_DELAY = 30
local IMPACT_FADE_DURATION = 5
local SHELL_LIFETIME = 30
local KEYBINDS = {
    test = { label = "F5", keys = { KEY_F5 } },
    confirm = { label = "F6", keys = { KEY_F6 } },
    restart = { label = "F7", keys = { KEY_F7 } },
    reset = { label = "F8", keys = { KEY_F8, KEY_DELETE } },
    refill = { label = "F9", keys = { KEY_F9, KEY_R } },
    exit = { label = "ESC", keys = { KEY_ESCAPE } },
}

local function patchShellLifetime()
    if EDITOR.ShellLifetimePatched or type(FAS2_MakeFakeShell) ~= "function" then
        return
    end

    EDITOR.ShellLifetimePatched = true

    local originalMakeFakeShell = FAS2_MakeFakeShell
    FAS2_MakeFakeShell = function(shell, pos, ang, vel, time, removetime)
        removetime = math.max(tonumber(removetime) or 0, SHELL_LIFETIME)
        return originalMakeFakeShell(shell, pos, ang, vel, time, removetime)
    end
end

timer.Simple(0, patchShellLifetime)
hook.Add("Think", "FAS2PatternEditor.PatchShellLifetime", patchShellLifetime)

local function chatMessage(prefixColor, messageColor, ...)
    chat.AddText(prefixColor, "[FAS2 Editor] ", messageColor, ...)
end

local function resetClientState()
    STATE.active = false
    STATE.preTestMode = false
    STATE.reviewMode = false
    STATE.testMode = false
    STATE.testPending = false
    STATE.testCountdownEnd = 0
    STATE.weaponClass = nil
    STATE.captureMode = nil
    STATE.maxShots = 0
    STATE.shots = {}
    STATE.testShots = {}
    STATE.trailPoints = {}
    STATE.referencePos = nil
    STATE.testReferencePos = nil
    STATE.wallDist = 0
    STATE.hasExistingPattern = false
    STATE.pendingPayload = nil
    STATE.testSummary = nil
    STATE.keyLatch = {}
    STATE.startPos = nil
    STATE.calibrationViewAngles = nil
    STATE.lastImpactTime = 0
    STATE.decalClearAt = 0
end

local function registerImpactTimestamp(timestamp)
    timestamp = tonumber(timestamp) or CurTime()
    STATE.lastImpactTime = timestamp
    STATE.decalClearAt = 0

    timer.Simple(0, function()
        if STATE.active and not STATE.preTestMode and not STATE.reviewMode and not STATE.testMode and not STATE.testPending then
            RunConsoleCommand("r_cleardecals")
        end
    end)
end

local function getOverlayFadeAlpha(recordedAt)
    local timestamp = tonumber(recordedAt)
    if not timestamp then
        return 1
    end

    local elapsed = CurTime() - timestamp
    if elapsed <= IMPACT_FADE_DELAY then
        return 1
    end

    if elapsed >= IMPACT_FADE_DELAY + IMPACT_FADE_DURATION then
        return 0
    end

    return 1 - math.Clamp((elapsed - IMPACT_FADE_DELAY) / IMPACT_FADE_DURATION, 0, 1)
end

local function getCurrentAimWallDistance(localPlayer)
    if not IsValid(localPlayer) then
        return nil, false
    end

    local startPos = localPlayer:GetShootPos()
    local trace = util.TraceLine({
        start = startPos,
        endpos = startPos + localPlayer:GetAimVector() * 120000,
        filter = localPlayer,
        mask = MASK_SHOT,
    })

    if not trace.Hit then
        return nil, false
    end

    return startPos:Distance(trace.HitPos), true
end

local function getRangeQuality(distanceUnits)
    distanceUnits = tonumber(distanceUnits) or 0
    if distanceUnits <= 0 then
        return "NO WALL", Color(255, 180, 80)
    end

    local meters = EDITOR.UnitsToMeters(distanceUnits)
    if distanceUnits < EDITOR.MinCalibrationUnits then
        return string.format("TOO CLOSE %.1fm", meters), Color(255, 180, 80)
    end

    if distanceUnits > EDITOR.MaxCalibrationUnits then
        return string.format("TOO FAR %.1fm", meters), Color(255, 120, 120)
    end

    local delta = math.abs(distanceUnits - EDITOR.RecommendedCalibrationUnits)
    if delta <= 236 then
        return string.format("GOOD %.1fm", meters), Color(80, 255, 120)
    end

    return string.format("OK %.1fm", meters), Color(120, 200, 255)
end

local function cancelCalibrationForMovement()
    STATE.shots = {}
    STATE.trailPoints = {}
    STATE.referencePos = nil
    STATE.wallDist = 0
    STATE.preTestMode = false
    STATE.reviewMode = false
    STATE.testMode = false
    STATE.testPending = false
    STATE.testCountdownEnd = 0
    STATE.pendingPayload = nil
    STATE.testShots = {}
    STATE.testReferencePos = nil
    STATE.testSummary = nil
    STATE.startPos = nil

    net.Start("FAS2PatternEditor.Refill")
    net.SendToServer()

    surface.PlaySound("buttons/button10.wav")
    chatMessage(Color(255, 120, 120), Color(255, 255, 255), "You moved after shot 1. Capture was reset, the magazine was refilled, and you can reposition before firing again.")
end

local function consumeKeyPress(latchKey, ...)
    STATE.keyLatch = STATE.keyLatch or {}

    local pressed = false
    for _, keyCode in ipairs({...}) do
        if input.IsKeyDown(keyCode) then
            pressed = true
            break
        end
    end

    if pressed and not STATE.keyLatch[latchKey] then
        STATE.keyLatch[latchKey] = true
        return true
    end

    if not pressed then
        STATE.keyLatch[latchKey] = false
    end

    return false
end

local function bindLabel(action)
    local bind = KEYBINDS[action]
    return bind and bind.label or "?"
end

local function bindPressed(latchKey, action)
    local bind = KEYBINDS[action]
    if not bind then
        return false
    end

    return consumeKeyPress(latchKey, unpack(bind.keys))
end

local function rebuildTrail()
    STATE.trailPoints = {}

    if #STATE.shots < 2 then
        return
    end

    local function catmullRom(t, p0, p1, p2, p3)
        local t2 = t * t
        local t3 = t2 * t

        return 0.5 * (
            (2 * p1) +
            (-p0 + p2) * t +
            (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 +
            (-p0 + 3 * p1 - 3 * p2 + p3) * t3
        )
    end

    local segmentsPerPair = 8

    for index = 1, #STATE.shots - 1 do
        local p0 = STATE.shots[math.max(1, index - 1)].pos
        local p1 = STATE.shots[index].pos
        local p2 = STATE.shots[math.min(#STATE.shots, index + 1)].pos
        local p3 = STATE.shots[math.min(#STATE.shots, index + 2)].pos

        for segment = 0, segmentsPerPair - 1 do
            local t = segment / segmentsPerPair
            table.insert(STATE.trailPoints, Vector(
                catmullRom(t, p0.x, p1.x, p2.x, p3.x),
                catmullRom(t, p0.y, p1.y, p2.y, p3.y),
                catmullRom(t, p0.z, p1.z, p2.z, p3.z)
            ))
        end
    end

    table.insert(STATE.trailPoints, STATE.shots[#STATE.shots].pos)
end

local function buildPatternPayload()
    if #STATE.shots < 2 then
        chatMessage(Color(255, 180, 80), Color(255, 255, 255), "Need at least two points to save a pattern.")
        return nil
    end

    local patternPoints = {}
    for index, shot in ipairs(STATE.shots) do
        patternPoints[index] = {
            p = tonumber(shot.cumulativePitch) or 0,
            y = tonumber(shot.cumulativeYaw) or 0,
        }
    end

    local localPlayer = LocalPlayer()
    local weapon = IsValid(localPlayer) and localPlayer:GetActiveWeapon() or nil
    local fireDelay = IsValid(weapon) and tonumber(weapon.FireDelay) or 0.1
    local captureMode = STATE.captureMode or ((IsValid(weapon) and weapon.dt and weapon.dt.Status == FAS_STAT_ADS) and "ads" or "hip")
    local sweetSpotDistance = IsValid(weapon) and tonumber(weapon.EffectiveRange) or nil
    if not sweetSpotDistance or sweetSpotDistance <= 0 then
        sweetSpotDistance = math.max(tonumber(STATE.wallDist) or 0, EDITOR.RecommendedCalibrationUnits)
    end

    return {
        version = 1,
        weaponClass = STATE.weaponClass,
        points = patternPoints,
        meta = {
            editorVersion = EDITOR.EditorVersion,
            shotCount = #patternPoints,
            calibrationDistance = math.Round(STATE.wallDist, 2),
            wallDistance = math.Round(STATE.wallDist, 2),
            sweetSpotDistance = math.Round(sweetSpotDistance, 2),
            resetDelay = math.max(fireDelay * 2.6, 0.18),
            captureMode = captureMode,
            adsMultiplier = 1,
            hipMultiplier = 1,
        },
    }
end

local function saveReviewedPattern()
    local payload = STATE.pendingPayload or buildPatternPayload()
    if not payload then
        return
    end

    EDITOR.Patterns[STATE.weaponClass] = payload
    EDITOR.InstallNativePattern(STATE.weaponClass, payload, true)

    file.CreateDir(EDITOR.DataDir)
    file.Write(EDITOR.DataFile, EDITOR.SerializePatterns())

    net.Start("FAS2PatternEditor.Save")
    net.WriteString(STATE.weaponClass)
    net.WriteString(util.TableToJSON(payload, false) or "{}")
    net.SendToServer()

    chatMessage(Color(80, 255, 120), Color(255, 255, 255), "Saved pattern for ", STATE.weaponClass, ".")
    RunConsoleCommand("fas2_pattern_editor_exit")
end

local function summarizeTestAccuracy()
    if type(STATE.pendingPayload) ~= "table" or type(STATE.pendingPayload.points) ~= "table" or #STATE.testShots == 0 or #STATE.shots == 0 then
        return nil
    end

    local totalAngleError = 0
    local maxAngleError = 0
    local totalPositionError = 0
    local maxPositionError = 0
    local exactAngleMatches = 0
    local exactPositionMatches = 0
    local exactCombinedMatches = 0
    local compared = math.min(#STATE.pendingPayload.points, #STATE.testShots, #STATE.shots)
    local angleTolerance = 0.01
    local positionTolerance = 0.1
    for index = 1, compared do
        local expected = STATE.pendingPayload.points[index] or {}
        local actual = STATE.testShots[index] or {}
        local captured = STATE.shots[index] or {}
        local pitchError = math.abs((tonumber(actual.cumulativePitch) or 0) - (tonumber(expected.p) or 0))
        local yawError = math.abs(normalizeAngle((tonumber(actual.cumulativeYaw) or 0) - (tonumber(expected.y) or 0)))
        local angleError = math.sqrt(pitchError * pitchError + yawError * yawError)
        totalAngleError = totalAngleError + angleError
        maxAngleError = math.max(maxAngleError, angleError)

        local positionError = 0
        if isvector(actual.pos) and isvector(captured.pos) then
            positionError = actual.pos:Distance(captured.pos)
        end

        totalPositionError = totalPositionError + positionError
        maxPositionError = math.max(maxPositionError, positionError)

        local angleExact = angleError <= angleTolerance
        local positionExact = positionError <= positionTolerance
        if angleExact then
            exactAngleMatches = exactAngleMatches + 1
        end
        if positionExact then
            exactPositionMatches = exactPositionMatches + 1
        end
        if angleExact and positionExact then
            exactCombinedMatches = exactCombinedMatches + 1
        end
    end

    local firstShotOffset = 0
    if isvector(STATE.testShots[1] and STATE.testShots[1].pos) and isvector(STATE.shots[1] and STATE.shots[1].pos) then
        firstShotOffset = STATE.testShots[1].pos:Distance(STATE.shots[1].pos)
    end

    return {
        compared = compared,
        averageAngleError = compared > 0 and totalAngleError / compared or 0,
        maxAngleError = maxAngleError,
        averagePositionError = compared > 0 and totalPositionError / compared or 0,
        maxPositionError = maxPositionError,
        firstShotOffset = firstShotOffset,
        exactAngleMatches = exactAngleMatches,
        exactPositionMatches = exactPositionMatches,
        exactCombinedMatches = exactCombinedMatches,
        angleTolerance = angleTolerance,
        positionTolerance = positionTolerance,
    }
end

local function beginPreTestReview()
    local payload = buildPatternPayload()
    if not payload then
        return
    end

    STATE.pendingPayload = payload
    STATE.preTestMode = true
    STATE.reviewMode = false
    STATE.testMode = false
    STATE.testPending = false
    STATE.testCountdownEnd = 0
    STATE.testSummary = nil

    chatMessage(Color(80, 255, 120), Color(255, 255, 255), "Capture complete for ", STATE.weaponClass, ".")
    chatMessage(Color(180, 180, 180), Color(255, 255, 255), string.format("Press %s to test this unsaved pattern. Press %s to remake the capture.", bindLabel("test"), bindLabel("restart")))
    chatMessage(Color(180, 180, 180), Color(255, 255, 255), string.format("Recorded mode: %s. Replay now uses the exact recorded path with no hip or ADS conversion.", string.upper(tostring((payload.meta and payload.meta.captureMode) or STATE.captureMode or "hip"))))
    chatMessage(Color(180, 180, 180), Color(255, 255, 255), "Line your crosshair up with the CENTER point first. When the test starts, the full world pattern will hide.")
end

local function beginPatternReview()
    STATE.preTestMode = false
    STATE.testMode = false
    local payload = buildPatternPayload()
    if payload then
        STATE.pendingPayload = payload
    end
    STATE.reviewMode = true
    STATE.testSummary = summarizeTestAccuracy()

    chatMessage(Color(80, 255, 120), Color(255, 255, 255), "Test complete for ", STATE.weaponClass, ".")
    if STATE.testSummary then
        chatMessage(Color(120, 200, 255), Color(255, 255, 255), string.format("Angle avg %.2f / max %.2f. Wall avg %.1fuu / max %.1fuu. First-shot offset %.1fuu over %d shots.", STATE.testSummary.averageAngleError or 0, STATE.testSummary.maxAngleError or 0, STATE.testSummary.averagePositionError or 0, STATE.testSummary.maxPositionError or 0, STATE.testSummary.firstShotOffset or 0, STATE.testSummary.compared or 0))
        chatMessage(Color(120, 200, 255), Color(255, 255, 255), string.format("Exact match: %d/%d shots within %.2f deg and %.2fuu.", STATE.testSummary.exactCombinedMatches or 0, STATE.testSummary.compared or 0, STATE.testSummary.angleTolerance or 0, STATE.testSummary.positionTolerance or 0))
    end
    chatMessage(Color(180, 180, 180), Color(255, 255, 255), string.format("Press %s to save, %s to retest, %s to remake the capture, %s to reset to default, %s to discard.", bindLabel("confirm"), bindLabel("test"), bindLabel("restart"), bindLabel("reset"), bindLabel("exit")))
    chatMessage(Color(180, 180, 180), Color(255, 255, 255), "You can also type !faspattern reset to restore the current weapon's default spray.")
end

local function beginPatternTest(payload, isRetest)
    payload = payload or STATE.pendingPayload or buildPatternPayload()
    if not payload then
        return
    end

    STATE.pendingPayload = payload
    if type(payload.meta) ~= "table" then
        payload.meta = {}
    end
    payload.meta.editorVersion = EDITOR.EditorVersion
    EDITOR.InstallNativePattern(STATE.weaponClass or payload.weaponClass, payload, true)
    STATE.preTestMode = false
    STATE.reviewMode = false
    STATE.testMode = false
    STATE.testPending = true
    STATE.testCountdownEnd = CurTime() + 3
    STATE.testShots = {}
    STATE.testReferencePos = nil
    STATE.testSummary = nil

    net.Start("FAS2PatternEditor.TestPattern")
    net.WriteString(STATE.weaponClass or "")
    net.WriteString(util.TableToJSON(payload, false) or "{}")
    net.SendToServer()

    if isRetest then
        chatMessage(Color(80, 255, 120), Color(255, 255, 255), "Retest queued for ", STATE.weaponClass, ".")
    else
        chatMessage(Color(80, 255, 120), Color(255, 255, 255), "Test queued for ", STATE.weaponClass, ".")
    end
    chatMessage(Color(180, 180, 180), Color(255, 255, 255), string.format("You are locked in place. Aim at the CENTER point now. The test mag loads after the countdown and the full pattern hides when the spray begins. Press %s to remake the capture if needed.", bindLabel("restart")))
end

local function resetPatternToDefault()
    if not STATE.weaponClass or STATE.weaponClass == "" then
        return
    end

    EDITOR.Patterns[STATE.weaponClass] = nil
    if FAS2_InstallCS2SprayReset then
        FAS2_InstallCS2SprayReset(false, STATE.weaponClass)
    end
    file.CreateDir(EDITOR.DataDir)
    file.Write(EDITOR.DataFile, EDITOR.SerializePatterns())

    net.Start("FAS2PatternEditor.Clear")
    net.WriteString(STATE.weaponClass)
    net.SendToServer()

    local scalePitch = tonumber(FAS2_CS2PatternScalePitch) or 1
    local scaleYaw = tonumber(FAS2_CS2PatternScaleYaw) or scalePitch
    chatMessage(Color(255, 180, 80), Color(255, 255, 255), string.format("Reset %s to tuned default spray (%.1fx pitch / %.1fx yaw).", STATE.weaponClass, scalePitch, scaleYaw))
    RunConsoleCommand("fas2_pattern_editor_exit")
end

concommand.Add("fas2_pattern_editor_reset_default", function()
    if not STATE.active then
        return
    end

    resetPatternToDefault()
end)

local function restartPattern()
    STATE.shots = {}
    STATE.trailPoints = {}
    STATE.referencePos = nil
    STATE.wallDist = 0
    STATE.preTestMode = false
    STATE.reviewMode = false
    STATE.testMode = false
    STATE.testPending = false
    STATE.testCountdownEnd = 0
    STATE.pendingPayload = nil
    STATE.captureMode = nil
    STATE.testShots = {}
    STATE.testReferencePos = nil
    STATE.testSummary = nil
    STATE.startPos = nil
    net.Start("FAS2PatternEditor.Refill")
    net.SendToServer()
    surface.PlaySound("buttons/button9.wav")
    chatMessage(Color(120, 200, 255), Color(255, 255, 255), "Restarted live capture and refilled the magazine. You can move before firing shot 1 again.")
end

local function restartPatternTest()
    if type(STATE.pendingPayload) ~= "table" or type(STATE.pendingPayload.points) ~= "table" or #STATE.pendingPayload.points < 2 then
        return
    end

    beginPatternTest(STATE.pendingPayload, true)
end

local function enterPaintMode()
    local localPlayer = LocalPlayer()
    if not IsValid(localPlayer) then
        return
    end

    local weaponClass = net.ReadString()
    local maxShots = net.ReadUInt(8)
    local hasExistingPattern = net.ReadBool()

    resetClientState()
    STATE.active = true
    STATE.weaponClass = weaponClass
    STATE.maxShots = maxShots
    STATE.hasExistingPattern = hasExistingPattern
    STATE.startPos = nil

    chatMessage(Color(80, 255, 120), Color(255, 255, 255), "Live pattern capture active for ", STATE.weaponClass, ".")
    chatMessage(Color(180, 180, 180), Color(255, 255, 255), "Move to the wall distance you want, then fire shot 1 to start calibration.")
    chatMessage(Color(180, 180, 180), Color(255, 255, 255), "During calibration the viewmodel stays visible and the weapon fires perfectly straight with zero recoil or spread. Only your mouse movement defines the pattern.")
    chatMessage(Color(180, 180, 180), Color(255, 255, 255), "After shot 1, movement locks and you can either hold the spray or tap-move-tap to place each point until the mag is empty.")

    if hasExistingPattern then
        chatMessage(Color(120, 200, 255), Color(255, 255, 255), "An existing saved pattern already exists for this weapon. New save will replace it.")
    end
end

exitPaintMode = function(showMessage)
    if showMessage and STATE.active then
        chatMessage(Color(255, 200, 80), Color(255, 255, 255), "Exited pattern painter.")
    end

    resetClientState()
end

net.Receive("FAS2PatternEditor.Enter", enterPaintMode)

net.Receive("FAS2PatternEditor.Exit", function()
    exitPaintMode(false)
end)

net.Receive("FAS2PatternEditor.Sync", function()
    EDITOR.LoadPatternsFromJSON(net.ReadString())
end)

net.Receive("FAS2PatternEditor.DebugMode", function()
    EDITOR.DebugEnabled = net.ReadBool()
    chatMessage(Color(120, 200, 255), Color(255, 255, 255), "Pattern debug ", EDITOR.DebugEnabled and "enabled" or "disabled", ".")
end)

net.Receive("FAS2PatternEditor.TestCountdown", function()
    local seconds = math.max(net.ReadUInt(3), 1)
    STATE.preTestMode = false
    STATE.reviewMode = false
    STATE.testMode = false
    STATE.testPending = true
    STATE.testCountdownEnd = CurTime() + seconds
end)

net.Receive("FAS2PatternEditor.TestBegin", function()
    STATE.preTestMode = false
    STATE.reviewMode = false
    STATE.testPending = false
    STATE.testMode = true
    STATE.testCountdownEnd = 0
    STATE.testShots = {}
    STATE.testReferencePos = nil
    chatMessage(Color(80, 255, 120), Color(255, 255, 255), "Test pass live. Keep the first CENTER point lined up, then fire the spray.")
    chatMessage(Color(180, 180, 180), Color(255, 255, 255), "The full world pattern is hidden during the test. Press R any time to reload and test the same unsaved spray again.")
end)

local function recordLiveShot(startPos, hitPos, shotIndex, maxShots)
    if not STATE.active then
        return
    end

    shotIndex = math.max(math.floor(tonumber(shotIndex) or (#STATE.shots + 1)), 1)
    if shotIndex > STATE.maxShots then
        return
    end

    local traceStart = isvector(startPos) and Vector(startPos) or vector_origin
    local traceHitPos = isvector(hitPos) and Vector(hitPos) or traceStart
    local cumulativePitch = 0
    local cumulativeYaw = 0

    if shotIndex == 1 or not isvector(STATE.referencePos) then
        local localPlayer = LocalPlayer()
        STATE.startPos = IsValid(localPlayer) and Vector(localPlayer:GetPos()) or nil
        local activeWeapon = IsValid(localPlayer) and localPlayer:GetActiveWeapon() or nil
        STATE.captureMode = (IsValid(activeWeapon) and activeWeapon.dt and activeWeapon.dt.Status == FAS_STAT_ADS) and "ads" or "hip"
        STATE.referencePos = Vector(traceHitPos)
        STATE.wallDist = traceStart:Distance(traceHitPos)
    else
        local referenceDirection = (STATE.referencePos - traceStart):GetNormalized()
        local hitDirection = (traceHitPos - traceStart):GetNormalized()
        local referenceAngles = referenceDirection:Angle()
        local hitAngles = hitDirection:Angle()

        cumulativePitch = normalizeAngle(hitAngles.p - referenceAngles.p)
        cumulativeYaw = normalizeAngle(hitAngles.y - referenceAngles.y)
    end

    STATE.maxShots = math.max(math.floor(tonumber(maxShots) or STATE.maxShots), STATE.maxShots)
    STATE.shots[shotIndex] = {
        index = shotIndex,
        pos = Vector(traceHitPos),
        cumulativePitch = cumulativePitch,
        cumulativeYaw = cumulativeYaw,
        recordedAt = CurTime(),
    }

    registerImpactTimestamp(CurTime())
    rebuildTrail()
    surface.PlaySound("buttons/button15.wav")

    if shotIndex >= STATE.maxShots then
        timer.Simple(0.2, function()
            if STATE.active then
                beginPreTestReview()
            end
        end)
    end
end

net.Receive("FAS2PatternEditor.RecordShot", function()
    local startPos = net.ReadVector()
    local hitPos = net.ReadVector()
    local shotIndex = net.ReadUInt(8)
    local maxShots = net.ReadUInt(8)
    local isTest = net.ReadBool()

    if not isTest then
        recordLiveShot(startPos, hitPos, shotIndex, maxShots)
        return
    end

    if not STATE.active or not STATE.testMode then
        return
    end

    local traceStart = isvector(startPos) and Vector(startPos) or vector_origin
    local traceHitPos = isvector(hitPos) and Vector(hitPos) or traceStart
    local cumulativePitch = 0
    local cumulativeYaw = 0

    if shotIndex == 1 or not isvector(STATE.testReferencePos) then
        STATE.testReferencePos = Vector(traceHitPos)
    else
        local referenceDirection = (STATE.testReferencePos - traceStart):GetNormalized()
        local hitDirection = (traceHitPos - traceStart):GetNormalized()
        local referenceAngles = referenceDirection:Angle()
        local hitAngles = hitDirection:Angle()

        cumulativePitch = normalizeAngle(hitAngles.p - referenceAngles.p)
        cumulativeYaw = normalizeAngle(hitAngles.y - referenceAngles.y)
    end

    STATE.testShots[shotIndex] = {
        index = shotIndex,
        pos = Vector(traceHitPos),
        cumulativePitch = cumulativePitch,
        cumulativeYaw = cumulativeYaw,
        recordedAt = CurTime(),
    }

    registerImpactTimestamp(CurTime())
    surface.PlaySound("buttons/button15.wav")

    if shotIndex >= maxShots then
        timer.Simple(0.2, function()
            if STATE.active then
                beginPatternReview()
            end
        end)
    end
end)

concommand.Add("fas2_pattern_editor_review_save", function()
    if not STATE.active or not STATE.reviewMode then
        return
    end

    saveReviewedPattern()
end)

concommand.Add("fas2_pattern_editor_review_redo", function()
    if not STATE.active then
        return
    end

    restartPattern()
end)

concommand.Add("fas2_pattern_editor_review_reset", function()
    if not STATE.active or not STATE.reviewMode then
        return
    end

    resetPatternToDefault()
end)

concommand.Add("fas2_pattern_editor_review_discard", function()
    if not STATE.active then
        return
    end

    exitPaintMode(true)
    RunConsoleCommand("fas2_pattern_editor_exit")
end)

hook.Add("CreateMove", "FAS2PatternEditor.BlockAttackClient", function(cmd)
    if not STATE.active then
        return
    end

    local localPlayer = LocalPlayer()
    local activeWeapon = IsValid(localPlayer) and localPlayer:GetActiveWeapon() or nil
    if EDITOR.ShouldUseLaserCalibration(activeWeapon) then
        EDITOR.ResetLaserCalibrationState(activeWeapon)
    end

    -- During capture: let the player freely move their mouse to draw the pattern.
    -- Recoil is suppressed, so only genuine mouse input changes eye angles.
    if not STATE.preTestMode and not STATE.reviewMode and not STATE.testMode and not STATE.testPending then
        if not isangle(STATE.calibrationViewAngles) and cmd.GetViewAngles then
            STATE.calibrationViewAngles = Angle(cmd:GetViewAngles().p, cmd:GetViewAngles().y, 0)
        end
    end

    local buttons = cmd:GetButtons()
    buttons = bit.band(buttons, bit.bnot(IN_RELOAD))

    if STATE.preTestMode or STATE.reviewMode or STATE.testPending then
        buttons = bit.band(buttons, bit.bnot(IN_ATTACK + IN_ATTACK2))
    end

    local movementLocked = (not STATE.reviewMode) and ((#STATE.shots > 0) or STATE.preTestMode or STATE.testMode or STATE.testPending)
    if movementLocked then
        buttons = bit.band(buttons, bit.bnot(IN_FORWARD + IN_BACK + IN_MOVELEFT + IN_MOVERIGHT + IN_JUMP + IN_DUCK + IN_SPEED + IN_WALK))
        cmd:SetForwardMove(0)
        cmd:SetSideMove(0)
        cmd:SetUpMove(0)
    end

    cmd:SetButtons(buttons)
end)

-- Client-side bullet override: force predicted bullets straight during calibration and test
-- so the visual wall impacts match the server recording.
hook.Add("EntityFireBullets", "FAS2PatternEditor.ClientBulletOverride", function(entity, bulletData)
    if not STATE.active then
        return
    end

    local localPlayer = LocalPlayer()
    if not IsValid(localPlayer) or entity ~= localPlayer then
        return
    end

    -- During calibration: bullets go exactly where raw eye angles point.
    -- During test, leave bulletData alone so predicted impacts mirror the
    -- native FA:S spray path we are validating.
    if not STATE.preTestMode and not STATE.reviewMode and not STATE.testPending and not STATE.testMode then
        local aimAngles = localPlayer:EyeAngles()

        bulletData.Dir = aimAngles:Forward()
        bulletData.Spread = vector_origin
        bulletData.Num = 1
        return true
    end
end)

hook.Add("Think", "FAS2PatternEditor.Input", function()
    if not STATE.active then
        return
    end

    local localPlayer = LocalPlayer()
    if not IsValid(localPlayer) then
        return
    end

    local weapon = localPlayer:GetActiveWeapon()
    if not EDITOR.IsSupportedWeapon(weapon) or weapon:GetClass() ~= STATE.weaponClass then
        RunConsoleCommand("fas2_pattern_editor_exit")
        return
    end

    if STATE.preTestMode then
        if bindPressed("pretest_start", "test") then
            beginPatternTest(STATE.pendingPayload, false)
        end

        if bindPressed("pretest_redo", "restart") then
            restartPattern()
        end

        if bindPressed("pretest_refill", "refill") then
            restartPattern()
        end

        if bindPressed("pretest_reset", "reset") then
            resetPatternToDefault()
        end

        if bindPressed("pretest_discard", "exit") then
            exitPaintMode(true)
            RunConsoleCommand("fas2_pattern_editor_exit")
        end

        return
    end

    if STATE.reviewMode then
        if bindPressed("save", "confirm") then
            saveReviewedPattern()
        end

        if bindPressed("reset", "reset") then
            resetPatternToDefault()
        end

        if bindPressed("retest", "test") then
            restartPatternTest()
        end

        if bindPressed("remake", "restart") then
            restartPattern()
        end

        if bindPressed("discard", "exit") then
            exitPaintMode(true)
            RunConsoleCommand("fas2_pattern_editor_exit")
        end

        return
    end

    if STATE.testMode then
        if bindPressed("test_retest", "test") then
            restartPatternTest()
        end

        if bindPressed("test_refill", "refill") then
            restartPatternTest()
        end

        if bindPressed("test_finish", "confirm") then
            if #STATE.testShots > 0 then
                beginPatternReview()
            else
                surface.PlaySound("buttons/button10.wav")
                chatMessage(Color(255, 180, 80), Color(255, 255, 255), "Fire at least one test shot before continuing to review.")
            end
        end

        if bindPressed("test_remake", "restart") then
            restartPattern()
        end

        if bindPressed("test_discard", "exit") then
            exitPaintMode(true)
            RunConsoleCommand("fas2_pattern_editor_exit")
        end

        return
    end

    if STATE.testPending then
        if bindPressed("test_pending_remake", "restart") then
            restartPattern()
        end

        if bindPressed("test_pending_discard", "exit") then
            exitPaintMode(true)
            RunConsoleCommand("fas2_pattern_editor_exit")
        end

        return
    end

    if bindPressed("capture_redo", "restart") then
        restartPattern()
    end

    if bindPressed("capture_refill", "refill") then
        restartPattern()
    end

    if bindPressed("capture_reset", "reset") then
        resetPatternToDefault()
    end

    if bindPressed("capture_exit", "exit") then
        exitPaintMode(true)
        RunConsoleCommand("fas2_pattern_editor_exit")
    end
end)

hook.Add("Think", "FAS2PatternEditor.DecalCleanup", function()
    return
end)

hook.Add("PostDrawTranslucentRenderables", "FAS2PatternEditor.WorldOverlay", function(_, drawingSkybox)
    if drawingSkybox or not STATE.active or STATE.testMode then
        return
    end

    if #STATE.shots < 1 then
        return
    end

    render.SetColorMaterial()

    for index, shot in ipairs(STATE.shots) do
        if not isvector(shot.pos) then
            continue
        end

        local frac = index / math.max(STATE.maxShots, 1)
        local alpha = math.floor(135 * getOverlayFadeAlpha(shot.recordedAt))
        if alpha <= 0 then
            continue
        end

        local color = Color(math.floor(80 + 160 * frac), math.floor(255 - 120 * frac), 80, alpha)
        local radius = index == 1 and 2.8 or 1.8
        render.DrawSphere(shot.pos, radius, 10, 10, color)

        local nextShot = STATE.shots[index + 1]
        if nextShot and isvector(nextShot.pos) then
            render.DrawLine(shot.pos, nextShot.pos, Color(110, 220, 140, math.floor(alpha * 0.75)), true)
        end
    end
end)

hook.Add("HUDPaint", "FAS2PatternEditor.HUD", function()
    if not STATE.active then
        return
    end

    local screenWidth, screenHeight = ScrW(), ScrH()
    local localPlayer = LocalPlayer()
    local shotCount = #STATE.shots
    local testShotCount = #STATE.testShots
    local displayShotCount = (STATE.testMode or STATE.testPending) and testShotCount or shotCount
    local shotsLeft = math.max(STATE.maxShots - displayShotCount, 0)
    local shotLabel = math.min(displayShotCount, STATE.maxShots)
    local shotPrefix = (STATE.testMode or STATE.testPending) and "Test" or "Recorded"
    local liveWeapon = IsValid(localPlayer) and localPlayer:GetActiveWeapon() or nil
    local modeLabel = string.upper(STATE.captureMode or ((IsValid(liveWeapon) and liveWeapon.dt and liveWeapon.dt.Status == FAS_STAT_ADS) and "ads" or "hip"))
    local previewDistanceUnits, hasPreviewDistance = getCurrentAimWallDistance(localPlayer)
    local previewDistanceMeters = hasPreviewDistance and EDITOR.UnitsToMeters(previewDistanceUnits) or nil
    local rangeText, rangeColor = getRangeQuality(STATE.wallDist > 0 and STATE.wallDist or previewDistanceUnits)
    local fireModeText = IsValid(liveWeapon) and tostring(liveWeapon.FireMode or "?"):upper() or "?"
    local panelWidth, panelHeight = 520, 78
    local panelX = (screenWidth - panelWidth) * 0.5
    local panelY = 16
    local titleText = "FAS2 LIVE PATTERN CAPTURE"
    local titleColor = Color(80, 255, 120)

    if STATE.preTestMode then
        titleText = "FAS2 CAPTURE READY"
        titleColor = Color(120, 200, 255)
    elseif STATE.reviewMode then
        titleText = "FAS2 TEST REVIEW"
        titleColor = Color(120, 200, 255)
    elseif STATE.testPending or STATE.testMode then
        titleText = "FAS2 PATTERN TEST"
        titleColor = Color(255, 215, 120)
    end

    surface.SetDrawColor(18, 20, 24, 225)
    surface.DrawRect(panelX, panelY, panelWidth, panelHeight)
    surface.SetDrawColor(80, 220, 140, 180)
    surface.DrawOutlinedRect(panelX, panelY, panelWidth, panelHeight)

    draw.SimpleText(titleText, "DermaDefaultBold", panelX + panelWidth * 0.5, panelY + 14, titleColor, TEXT_ALIGN_CENTER)
    if STATE.testMode or STATE.testPending or STATE.reviewMode then
        draw.SimpleText(string.format("%s  |  %s  |  %s  |  REC %d/%d  TEST %d/%d", STATE.weaponClass or "", modeLabel, fireModeText, shotCount, STATE.maxShots, testShotCount, STATE.maxShots), "DermaDefault", panelX + panelWidth * 0.5, panelY + 34, Color(255, 255, 255), TEXT_ALIGN_CENTER)
    else
        draw.SimpleText(string.format("%s  |  %s  |  %s  |  %s %d/%d  |  %d left", STATE.weaponClass or "", modeLabel, fireModeText, shotPrefix, shotLabel, STATE.maxShots, shotsLeft), "DermaDefault", panelX + panelWidth * 0.5, panelY + 34, Color(255, 255, 255), TEXT_ALIGN_CENTER)
    end
    draw.SimpleText("RANGE " .. rangeText, "DermaDefaultBold", panelX + panelWidth * 0.5, panelY + 51, rangeColor, TEXT_ALIGN_CENTER)

    local barX = panelX + 18
    local barY = panelY + 66
    local barWidth = panelWidth - 36
    local barHeight = 8
    local fillWidth = STATE.maxShots > 0 and (displayShotCount / STATE.maxShots) * barWidth or 0

    surface.SetDrawColor(45, 45, 45, 220)
    surface.DrawRect(barX, barY, barWidth, barHeight)
    surface.SetDrawColor(80, 220, 140, 220)
    surface.DrawRect(barX, barY, fillWidth, barHeight)

    local footerY = screenHeight - 58
    surface.SetDrawColor(12, 12, 12, 185)
    surface.DrawRect(0, footerY, screenWidth, 58)
    if STATE.preTestMode then
        draw.SimpleText(string.format("%s test   %s redo   %s refill   %s tuned default   %s exit   , firemode", bindLabel("test"), bindLabel("restart"), bindLabel("refill"), bindLabel("reset"), bindLabel("exit")), "DermaDefault", screenWidth * 0.5, footerY + 16, Color(220, 220, 220), TEXT_ALIGN_CENTER)
    elseif STATE.reviewMode then
        draw.SimpleText(string.format("%s save   %s retest   %s redo   %s tuned default   %s exit", bindLabel("confirm"), bindLabel("test"), bindLabel("restart"), bindLabel("reset"), bindLabel("exit")), "DermaDefault", screenWidth * 0.5, footerY + 16, Color(220, 220, 220), TEXT_ALIGN_CENTER)
    elseif STATE.testPending then
        local secondsLeft = math.max(math.ceil((STATE.testCountdownEnd or 0) - CurTime()), 0)
        draw.SimpleText(string.format("AIM AT CENTER  |  TEST IN %d  |  %s redo   %s exit", secondsLeft, bindLabel("restart"), bindLabel("exit")), "DermaDefault", screenWidth * 0.5, footerY + 16, Color(220, 220, 220), TEXT_ALIGN_CENTER)
    elseif STATE.testMode then
        draw.SimpleText(string.format("TEST LIVE: %s retest   %s review   %s redo   %s refill   %s exit", bindLabel("test"), bindLabel("confirm"), bindLabel("restart"), bindLabel("refill"), bindLabel("exit")), "DermaDefault", screenWidth * 0.5, footerY + 16, Color(220, 220, 220), TEXT_ALIGN_CENTER)
    else
        draw.SimpleText(string.format("CAPTURE: tap shots   %s redo   %s refill   %s tuned default   %s exit   , firemode", bindLabel("restart"), bindLabel("refill"), bindLabel("reset"), bindLabel("exit")), "DermaDefault", screenWidth * 0.5, footerY + 16, Color(220, 220, 220), TEXT_ALIGN_CENTER)
    end

    if STATE.preTestMode then
        draw.SimpleText(string.format("Capture locked in. Aim at the first CENTER point, then press %s to start the hidden-overlay test.", bindLabel("test")), "DermaDefault", screenWidth * 0.5, footerY + 35, Color(140, 190, 255), TEXT_ALIGN_CENTER)
    elseif STATE.reviewMode then
        if STATE.testSummary then
            draw.SimpleText(string.format("Angle avg %.2f / max %.2f | Wall avg %.1fuu / max %.1fuu | First %.1fuu | %d shots", STATE.testSummary.averageAngleError or 0, STATE.testSummary.maxAngleError or 0, STATE.testSummary.averagePositionError or 0, STATE.testSummary.maxPositionError or 0, STATE.testSummary.firstShotOffset or 0, STATE.testSummary.compared or 0), "DermaDefault", screenWidth * 0.5, footerY + 35, Color(140, 190, 255), TEXT_ALIGN_CENTER)
        else
            draw.SimpleText(string.format("Review the tested spray, then press %s to save it or %s to rerun the same unsaved test.", bindLabel("confirm"), bindLabel("test")), "DermaDefault", screenWidth * 0.5, footerY + 35, Color(140, 190, 255), TEXT_ALIGN_CENTER)
        end
    elseif STATE.testPending then
        local secondsLeft = math.max(math.ceil((STATE.testCountdownEnd or 0) - CurTime()), 0)
        draw.SimpleText(string.format("Center your aim now. In %d second(s) you will be reset to the capture origin and the full overlay will hide for the test.", secondsLeft), "DermaDefault", screenWidth * 0.5, footerY + 35, Color(140, 190, 255), TEXT_ALIGN_CENTER)
    elseif STATE.testMode then
        if testShotCount == 0 then
            draw.SimpleText("Keep the first CENTER point lined up. After shot 1, the overlay stays hidden while you test the spray.", "DermaDefault", screenWidth * 0.5, footerY + 35, Color(140, 190, 255), TEXT_ALIGN_CENTER)
        else
            draw.SimpleText(string.format("Overlay hidden. Finish the spray, press %s to reload or retest, or %s to go to review.", bindLabel("test"), bindLabel("confirm")), "DermaDefault", screenWidth * 0.5, footerY + 35, Color(140, 190, 255), TEXT_ALIGN_CENTER)
        end
    elseif STATE.wallDist > 0 then
        draw.SimpleText(string.format("Calibration locked at %.1fm. Shoot one point per tap; saved sweet spot stays weapon-based, not wall-distance based.", EDITOR.UnitsToMeters(STATE.wallDist)), "DermaDefault", screenWidth * 0.5, footerY + 35, Color(140, 190, 255), TEXT_ALIGN_CENTER)
    elseif hasPreviewDistance then
        draw.SimpleText(string.format("Face a flat wall around 20-35m. Current %.1fm. Fire shot 1 to lock capture distance.", previewDistanceMeters or 0), "DermaDefault", screenWidth * 0.5, footerY + 35, Color(140, 190, 255), TEXT_ALIGN_CENTER)
    else
        draw.SimpleText(string.format("Face a flat wall around 20-35m, then fire shot 1 as CENTER. %s restores default.", bindLabel("reset")), "DermaDefault", screenWidth * 0.5, footerY + 35, Color(140, 190, 255), TEXT_ALIGN_CENTER)
    end

    local showFullPattern = not STATE.testMode
    local showCenterOnly = STATE.testMode and testShotCount == 0 and STATE.shots[1] ~= nil

    if showFullPattern then
        for index, shot in ipairs(STATE.shots) do
            local alphaMul = getOverlayFadeAlpha(shot.recordedAt)
            if alphaMul <= 0 then
                continue
            end

            local screenPos = shot.pos:ToScreen()
            if screenPos.visible then
                local frac = index / math.max(STATE.maxShots, 1)
                local red = math.floor(80 + 160 * frac)
                local green = math.floor(255 - 120 * frac)
                local size = index == 1 and 14 or 10
                local halo = index == shotCount and 18 or size + 6
                local outlineAlpha = math.floor(220 * alphaMul)
                local haloAlpha = math.floor(70 * alphaMul)
                local textAlpha = math.floor(220 * alphaMul)
                local coreAlpha = math.floor(190 * alphaMul)

                surface.DrawCircle(screenPos.x, screenPos.y, halo * 0.5, Color(red, green, 80, haloAlpha))
                surface.DrawCircle(screenPos.x, screenPos.y, size * 0.5, Color(red, green, 80, outlineAlpha))
                surface.DrawCircle(screenPos.x, screenPos.y, math.max(size * 0.2, 2), Color(12, 12, 12, coreAlpha))
                surface.DrawCircle(screenPos.x, screenPos.y, math.max(size * 0.1, 1), Color(235, 235, 235, math.floor(50 * alphaMul)))
                if EDITOR.DebugEnabled then
                    draw.SimpleText(tostring(index), "DermaDefault", screenPos.x + size + 4, screenPos.y - 6, Color(red, green, 80, textAlpha))
                    draw.SimpleText(string.format("x %.2f y %.2f", tonumber(shot.cumulativeYaw) or 0, tonumber(shot.cumulativePitch) or 0), "DermaDefault", screenPos.x + size + 4, screenPos.y + 6, Color(220, 220, 220, textAlpha))
                end

                if index == 1 then
                    draw.SimpleText("CENTER", "DermaDefaultBold", screenPos.x + size + 24, screenPos.y - 6, Color(80, 255, 120, outlineAlpha))
                end
            end
        end

        for index = 1, #STATE.trailPoints - 1 do
            local alphaA = getOverlayFadeAlpha(STATE.shots[index] and STATE.shots[index].recordedAt)
            local alphaB = getOverlayFadeAlpha(STATE.shots[index + 1] and STATE.shots[index + 1].recordedAt)
            local lineAlpha = math.floor(130 * math.min(alphaA, alphaB))
            if lineAlpha <= 0 then
                continue
            end

            local pointA = STATE.trailPoints[index]:ToScreen()
            local pointB = STATE.trailPoints[index + 1]:ToScreen()
            if pointA.visible and pointB.visible then
                surface.SetDrawColor(110, 220, 140, lineAlpha)
                surface.DrawLine(pointA.x, pointA.y, pointB.x, pointB.y)
            end
        end
    elseif showCenterOnly then
        local centerShot = STATE.shots[1]
        local alphaMul = centerShot and getOverlayFadeAlpha(centerShot.recordedAt) or 1
        if alphaMul <= 0 then
            return
        end
        local screenPos = centerShot.pos:ToScreen()
        if screenPos.visible then
            surface.DrawCircle(screenPos.x, screenPos.y, 10, Color(80, 255, 120, math.floor(70 * alphaMul)))
            surface.DrawCircle(screenPos.x, screenPos.y, 7, Color(80, 255, 120, math.floor(220 * alphaMul)))
            surface.DrawCircle(screenPos.x, screenPos.y, 2, Color(12, 12, 12, math.floor(200 * alphaMul)))
            draw.SimpleText("CENTER", "DermaDefaultBold", screenPos.x + 18, screenPos.y - 6, Color(80, 255, 120, math.floor(220 * alphaMul)))
        end
    end

    if EDITOR.DebugEnabled and not STATE.testMode then
        local previewX = 28
        local previewY = screenHeight - 250
        local previewSize = 170

        surface.SetDrawColor(12, 12, 12, 210)
        surface.DrawRect(previewX - 6, previewY - 24, previewSize + 12, previewSize + 36)
        draw.SimpleText("Pattern Preview", "DermaDefaultBold", previewX, previewY - 18, Color(120, 200, 255))

        local centerX = previewX + previewSize * 0.5
        local centerY = previewY + previewSize * 0.5
        surface.SetDrawColor(255, 255, 255, 35)
        surface.DrawLine(centerX - 22, centerY, centerX + 22, centerY)
        surface.DrawLine(centerX, centerY - 22, centerX, centerY + 22)

        if shotCount == 0 then
            draw.SimpleText("Awaiting shot 1", "DermaDefault", centerX, centerY - 6, Color(180, 180, 180), TEXT_ALIGN_CENTER)
            draw.SimpleText("Preview starts after first hit", "DermaDefault", centerX, centerY + 10, Color(140, 190, 255), TEXT_ALIGN_CENTER)
        else
            local maxOffset = 0.25
            for _, shot in ipairs(STATE.shots) do
                maxOffset = math.max(maxOffset, math.abs(shot.cumulativePitch or 0), math.abs(shot.cumulativeYaw or 0))
            end

            local scale = (previewSize * 0.5 - 12) / maxOffset
            local previousX = centerX
            local previousY = centerY

            for index, shot in ipairs(STATE.shots) do
                local dotX = centerX + (shot.cumulativeYaw or 0) * scale
                local dotY = centerY + (shot.cumulativePitch or 0) * scale

                if index > 1 then
                    surface.SetDrawColor(120, 120, 120, 90)
                    surface.DrawLine(previousX, previousY, dotX, dotY)
                end

                surface.SetDrawColor(80, 220, 140, 235)
                surface.DrawRect(dotX - 2, dotY - 2, 4, 4)
                previousX = dotX
                previousY = dotY
            end

            local lastShot = STATE.shots[shotCount]
            if lastShot then
                draw.SimpleText(string.format("Last point: #%d  x %.2f  y %.2f", shotCount, tonumber(lastShot.cumulativeYaw) or 0, tonumber(lastShot.cumulativePitch) or 0), "DermaDefault", previewX, previewY + previewSize + 12, Color(220, 220, 220))
            end
        end
    end

    local centerX = screenWidth * 0.5
    local centerY = screenHeight * 0.5
    surface.SetDrawColor(255, 255, 255, 200)
    surface.DrawLine(centerX - 14, centerY, centerX - 4, centerY)
    surface.DrawLine(centerX + 4, centerY, centerX + 14, centerY)
    surface.DrawLine(centerX, centerY - 14, centerX, centerY - 4)
    surface.DrawLine(centerX, centerY + 4, centerX, centerY + 14)
    surface.DrawRect(centerX, centerY, 1, 1)
end)

hook.Add("HUDPaint", "FAS2PatternEditor.SweetSpotHUD", function()
    if STATE.active then
        return
    end

    local localPlayer = LocalPlayer()
    if not IsValid(localPlayer) then
        return
    end

    local weapon = localPlayer:GetActiveWeapon()
    if not EDITOR.IsSupportedWeapon(weapon) then
        return
    end

    if not (weapon.dt and weapon.dt.Status == FAS_STAT_ADS) then
        return
    end

    local sweetSpotData = EDITOR.GetSweetSpotData(weapon)
    if not sweetSpotData then
        return
    end

    local statusColors = {
        OPTIMAL = Color(92, 255, 140, 240),
        CLOSE = Color(110, 205, 255, 240),
        STRETCH = Color(255, 214, 102, 240),
        FALLOFF = Color(255, 120, 120, 240),
    }

    local color = statusColors[sweetSpotData.status] or Color(220, 220, 220, 240)
    local targetText = sweetSpotData.targetDistanceMeters and string.format("TARGET %.0fm", sweetSpotData.targetDistanceMeters) or "TARGET --"
    local ammoText = sweetSpotData.ammoName == "standard" and "STD" or string.upper(sweetSpotData.ammoName)
    local bonusText = sweetSpotData.ammoMultiplier == 1 and "" or string.format("  |  %+.0f%% RANGE", (sweetSpotData.ammoMultiplier - 1) * 100)
    local panelWidth = 320
    local panelHeight = 52
    local centerX = ScrW() * 0.5
    local panelX = math.floor(centerX - panelWidth * 0.5)
    local panelY = math.floor(ScrH() * 0.5 - 108)

    surface.SetDrawColor(10, 12, 16, 195)
    surface.DrawRect(panelX, panelY, panelWidth, panelHeight)
    surface.SetDrawColor(color.r, color.g, color.b, 180)
    surface.DrawOutlinedRect(panelX, panelY, panelWidth, panelHeight)
    surface.DrawRect(panelX, panelY + panelHeight - 3, math.floor(panelWidth * math.Clamp(1 / math.max(sweetSpotData.spreadMultiplier, 0.01), 0.15, 1)), 3)

    draw.SimpleText(string.format("%s  |  SWEET %.0fm  |  %s", sweetSpotData.status, sweetSpotData.sweetSpotMeters, targetText), "DermaDefaultBold", centerX, panelY + 13, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(string.format("AMMO %s%s", ammoText, bonusText), "DermaDefault", centerX, panelY + 32, Color(225, 225, 225, 235), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)

print("[FAS2 Pattern Editor] Loaded")
