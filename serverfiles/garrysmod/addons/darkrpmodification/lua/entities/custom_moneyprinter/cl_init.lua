--[[---------------------------------------------------------------------------
This is an example of a custom entity.
---------------------------------------------------------------------------]]
include("shared.lua")

function ENT:Initialize()
end

function ENT:Draw()
    self:DrawModel()

    local Pos = self:GetPos()
    local Ang = self:GetAngles()

    local owner = self:Getowning_ent()
    owner = (IsValid(owner) and owner:Nick()) or DarkRP.getPhrase("unknown")
    local printerName = self:GetNWString("PrinterName", DarkRP.getPhrase("money_printer"))
    local storedMoney = DarkRP.formatMoney(self:GetStoredMoney())
    local upgrades = {}
    if self:GetHasCooler() then table.insert(upgrades, "Cooler") end
    if self:GetHasAmountUpgrade() then table.insert(upgrades, "Yield") end
    if self:GetHasTimerUpgrade() then table.insert(upgrades, "Timer") end
    if self:GetHasSilencer() then table.insert(upgrades, "Silencer") end
    if self:GetHasArmor() then table.insert(upgrades, "Armor") end
    local upgradeText = #upgrades > 0 and table.concat(upgrades, ", ") or "No upgrades"

    surface.SetFont("HUDNumber5")
    local TextWidth = surface.GetTextSize(printerName)
    local TextWidth2 = surface.GetTextSize(owner)
    local TextWidth3 = surface.GetTextSize(storedMoney)
    local TextWidth4 = surface.GetTextSize(upgradeText)

    Ang:RotateAroundAxis(Ang:Up(), 90)

    cam.Start3D2D(Pos + Ang:Up() * 11.5, Ang, 0.11)
        draw.WordBox(2, -TextWidth * 0.5, -60, printerName, "HUDNumber5", Color(140, 0, 0, 100), Color(255, 255, 255, 255))
        draw.WordBox(2, -TextWidth2 * 0.5, -18, owner, "HUDNumber5", Color(140, 0, 0, 100), Color(255, 255, 255, 255))
        draw.WordBox(2, -TextWidth3 * 0.5, 24, storedMoney, "HUDNumber5", Color(30, 100, 40, 140), Color(255, 255, 255, 255))
        draw.WordBox(2, -TextWidth4 * 0.5, 66, upgradeText, "HUDNumber5", Color(20, 20, 20, 140), Color(140, 210, 255, 255))
    cam.End3D2D()
end

function ENT:Think()
end
