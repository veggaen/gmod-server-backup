hook.Add("prone.Initialized", "ModernRPUI.ConfigureProneBind", function()
	RunConsoleCommand("prone_bindkey_enabled", "0")
	RunConsoleCommand("prone_bindkey_doubletap", "0")
end)

local holdDuration = 3
local holdStart = 0
local triggeredOnCurrentHold = false

local function resetProneHold()
	holdStart = 0
	triggeredOnCurrentHold = false
end

hook.Add("Think", "ModernRPUI.ProneAltHold", function()
	local ply = LocalPlayer()
	if not IsValid(ply) then
		resetProneHold()
		return
	end

	if gui.IsGameUIVisible() or gui.IsConsoleVisible() or vgui.GetKeyboardFocus() or ply:InVehicle() then
		resetProneHold()
		return
	end

	local altDown = input.IsKeyDown(KEY_LALT) or input.IsKeyDown(KEY_RALT)
	if not altDown then
		resetProneHold()
		return
	end

	if triggeredOnCurrentHold then
		return
	end

	if holdStart == 0 then
		holdStart = CurTime()
		return
	end

	if CurTime() - holdStart < holdDuration then
		return
	end

	triggeredOnCurrentHold = true

	if prone and prone.Request and ply.OnGround and ply:OnGround() and ply.IsProne and not ply:IsProne() then
		prone.Request()
		return
	end

	RunConsoleCommand("prone")
end)