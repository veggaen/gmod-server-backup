AddCSLuaFile()

ENT.Base = "wyozi_screenbase"

ENT.Author = "Wyozi"
ENT.PrintName = "Wyozi Screen: Projector"
ENT.Category = "Wyozi"

ENT.Spawnable = true
ENT.AdminSpawnable = true

ENT.Editable = true

ENT.Model = Model("models/dav0r/camera.mdl")

ENT.RenderData = {
	Width = 640,
	Height = 480,
	Projector = true
}

-- Hmm?
function ENT:CanEditVariables( ply )
	return ply:IsAdmin()
end