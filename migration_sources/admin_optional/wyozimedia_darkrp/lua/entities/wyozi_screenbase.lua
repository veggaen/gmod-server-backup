AddCSLuaFile()

ENT.Type = "anim"

--[[
ENT.Author = "Wyozi"
ENT.PrintName = "Wyozi Screen: Base"
ENT.Category = "Wyozi"

ENT.Spawnable = true
ENT.AdminSpawnable = true
]]

ENT.IsWyoziScreen = true

ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

ENT.Model = Model("models/dav0r/camera.mdl")

ENT.RenderData = {
	Width = 640,
	Height = 480,
	ProjectDir = Angle(0, 0, 0)
}

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "Link")
	self:NetworkVar("Float", 0, "StartedAt")

	self:NetworkVar("Float", 1, "DepthOffset", { KeyName = "depthoffset", Edit = { type = "Float", min = -1000, max = 1000, order = 1 } })
	self:NetworkVar("Float", 2, "WhiteScale", { KeyName = "whitescale", Edit = { type = "Float", min = 0, max = 10, order = 1 } })

	if SERVER then
		self:SetWhiteScale(1)
		self:SetDepthOffset(0.05) -- get rid of zfighting
	end

end

if SERVER then

	function ENT:Initialize()

		self:SetModel( self.Model )

		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )

		--if data.Static then
		--	self:SetMoveType( MOVETYPE_NONE )
		--else
			self:SetMoveType( MOVETYPE_VPHYSICS )
		--end
		
		local phys = self:GetPhysicsObject()
		if phys:IsValid() then
			phys:Wake()
		end

		self:SetUseType(SIMPLE_USE)

	end

	function ENT:PlayVideo(url, startat)
		self:SetLink(url)
		self:SetStartedAt(CurTime() - (startat or 0))
	end

	function ENT:StopVideo()
		self:SetLink("")
	end

	util.AddNetworkString("wyozimc_drp_play")

	function ENT:Use(activator)
		if activator:IsPlayer() then
			if self.AllowFunc and not self:AllowFunc(activator) then
				return
			end
			net.Start("wyozimc_gui")
				net.WriteBit(true)
				net.WriteString("wyozimc_drp_play")
				net.WriteEntity(self)
			net.Send(activator)
		end
	end

	function ENT:SetAllowFunc(func)
		self.AllowFunc = func
	end

	net.Receive("wyozimc_drp_play", function(le, cl)
		local url = net.ReadString()

		local provider, udata
		if url ~= "" then
			provider, udata = wyozimc.FindProvider(url)
			if not provider then
				cl:ChatPrint("invalid provider")
				return
			end
		end

		local ent = net.ReadEntity()
		if IsValid(ent) and ent.IsWyoziScreen then
			if ent.AllowFunc and not ent:AllowFunc(cl) then
				return
			end
			if url == "" then
				ent:StopVideo()
			else
				ent:PlayVideo(url, udata and udata.StartAt or 0)
			end
		end
	end)

end

if CLIENT then

	ENT.HTMLWidth = 1024

	function ENT:OnRemove()
		if IsValid(self.Browser) then
			self.Browser:Remove()
		end
	end

	function ENT:CreateBrowser()

		local browser = vgui.Create("DHTML")
        browser:SetMouseInputEnabled(false)
        browser:SetKeyboardInputEnabled(false)
        self.HTMLHeight = self.HTMLWidth * (self.RenderData.Height / self.RenderData.Width)
        browser:SetSize(self.HTMLWidth, self.HTMLHeight)
        browser:SetPaintedManually(true)
        browser:SetScrollbars(false)

		local oldFunc = browser.OpenURL
		browser.OpenURL = function( panel, url, history )
			panel.URL = url
			oldFunc( panel, url )
		end
		local oldFunc2 = browser.SetHTML
		browser.SetHTML = function( panel, html, origUrl )
			panel.URL = origUrl
			oldFunc2( panel, html )
		end

        browser:SetHTML("")

        self.Browser = browser
	end

	function ENT:DestroyBrowser()
		local browser = self.Browser
		browser:Remove()

		if IsValid(self.SoundChannel) then
			self.SoundChannel:Stop()
		end

		self.OpenedURL = nil
		self.TranslatingURL = false
	end

	function ENT:OnRemove()
		if IsValid(self.Browser) then
			self:DestroyBrowser()
		end
	end

	function ENT:ShouldDestroyBrowser(is_dead)
		if not cvars.Bool("wyozimc_enabled") then return true end

		local tdist = is_dead and 1100 or 1500 -- Makes it so distance at which browser creates/destroys isnt same. This is to make it impossible to walk forward and back and spam browser creation, thus lagging a lot
		return LocalPlayer():GetPos():Distance(self:GetPos()) > tdist
	end

	function ENT:GetPlayerVolume()
		local dist = LocalPlayer():GetPos():Distance(self:GetPos())
		local trace = { start = self:GetPos(), endpos = LocalPlayer():EyePos(), filter = self }
        local tr = util.TraceLine( trace ) 

		local m = 1
		if tr.HitWorld then
			m = 2
		end

		local v = math.Clamp(1 - ((dist*m) / 1000), 0, 1)

		v = v * wyozimc.GetMasterVolume()

		return v
	end

	function ENT:SetPlayUrl(provider, data, url)
		self.TranslatingURL = false

		self.Browser:SetHTML("")
		if IsValid(self.SoundChannel) then
			self.SoundChannel:Stop()
		end

		if provider.UseGmodPlayer then

			sound.PlayURL(url, "3d", function(channel)
				self.SoundChannel = channel
			end)

		else

			local browser = self.Browser
			if not IsValid(browser) then return end

			if provider.SetHTML then
				wyozimc.Debug("Trying to set html to sc " , url)
				browser:SetHTML(provider.SetHTML(data, url), url)
			else
				wyozimc.Debug("Trying to play" , url)
				browser:OpenURL(url)
			end

		end
	end

	function ENT:IsBlankPage()
		return self.Browser:IsValid() and self.Browser.URL == nil
	end

	function ENT:Think()
		local browser = self.Browser
		if self:ShouldDestroyBrowser(not IsValid(browser)) then
			if IsValid(browser) then
				self:DestroyBrowser()
			end
		else
			if not IsValid(browser) then
		        self:CreateBrowser()
		    elseif (self:GetLink() ~= "" or browser.URL ~= nil) and self.OpenedURL ~= self:GetLink() then
		    	if self:GetLink() == "" then
	       			browser:SetHTML("")
	       		elseif not self.TranslatingURL then
	       			local url = self:GetLink()
	       			local provider, udata = wyozimc.FindProvider(url)
					if not provider then
						MsgN("Trying to play something with no provider: " .. tostring(url))
						return
					end
					self.MediaProvider = provider
					self.TranslatingURL = true
					self.OpenedURL = url
					wyozimc.Debug("Translating url ", url)

					udata.StartAt = (CurTime() - self:GetStartedAt())
					self.PlayStarted = CurTime()

					if provider.TranslateUrl then
						provider.TranslateUrl(udata, function(url)
							self:SetPlayUrl(provider, udata, url)
						end)
					else
						self:SetPlayUrl(provider, udata, url)
					end

					if provider.QueryMeta then
						provider.QueryMeta(udata, function(qdata)
							self.QueryData = qdata
						end, function(msg) end)
					end

		    	end
			end

			if self.MediaProvider and self.MediaProvider.FuncSetVolume then
				local volmul = self:GetPlayerVolume()
				if volmul ~= self.LastVolume or (self.PlayStarted and self.PlayStarted > CurTime() - 2) then
					self.LastVolume = volmul

					if IsValid(self.Browser) then
						self.Browser:QueueJavascript(self.MediaProvider.FuncSetVolume(volmul))
					end
					--if IsValid(self.SoundChannel) then
					--	self.MediaProvider.FuncSetVolume(volmul, self.SoundChannel)
					--end
				end
			end
			if IsValid(self.SoundChannel) then
				self.SoundChannel:SetPos(self:GetPos())
			end
		end
	end

	function ENT:DrawScreen()
		render.PushFilterMin( TEXFILTER.ANISOTROPIC )
		render.PushFilterMag( TEXFILTER.ANISOTROPIC )

		self.Browser:SetPaintedManually(false)
		self.Browser:PaintManual()
		self.Browser:SetPaintedManually(true)

		render.PopFilterMin()
		render.PopFilterMag()
	end
	
	function ENT:Draw()
		self:DrawModel()

		if not self.RenderData or self.RenderData.AudioOnly then return end

		render.SuppressEngineLighting(true)

		local pos, ang
		local scalemul = 1
		local draw_scale

		self.HTMLHeight = self.HTMLHeight or 0

		if self.RenderData.Projector then
			local midpos = self:LocalToWorld(self:OBBCenter())

			local vecdir = self:GetForward() - self:GetRight()*0.1
			local tr = util.QuickTrace(midpos, midpos + vecdir * 10000, self)
			pos = tr.HitPos
			ang = tr.HitNormal:Angle()

            ang:RotateAroundAxis(ang:Right(), -90)
            ang:RotateAroundAxis(ang:Up(), 90)
            draw_scale = math.Clamp(pos:Distance(midpos) * 0.001 * self:GetWhiteScale(), 0.001, 100)

            pos = pos - ang:Right()*draw_scale*self.HTMLWidth*0.4

            pos = pos - ang:Forward()*draw_scale*self.HTMLHeight*0.65

            self:SetRenderBoundsWS(self:GetPos() - vecdir*1000, tr.HitPos + vecdir*1000)

            pos = pos + tr.HitNormal * self:GetDepthOffset()
                
		else
			pos = self:LocalToWorld(self.RenderData.Offset)
			ang = self:LocalToWorldAngles(self.RenderData.Rotation)
			draw_scale = self.RenderData.Width / self.HTMLWidth
		end

		cam.Start3D2D(pos, ang, draw_scale)
			surface.SetDrawColor(0, 0, 0)
			surface.DrawRect(0, 0, self.HTMLWidth, self.HTMLHeight)

			if IsValid(self.Browser) then
				self:DrawScreen()
			end

			if not IsValid(self.Browser) or self:IsBlankPage() then
				surface.SetDrawColor(0, 0, 0)
				surface.DrawRect(0, 0, self.HTMLWidth, self.HTMLHeight)

				draw.SimpleText("No media. Press 'e' on the projector/TV.", "DermaLarge", self.HTMLWidth/2, self.HTMLHeight/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
		cam.End3D2D()

		render.SuppressEngineLighting(false)

	end
end

-- Stupid darkrp stuff
function ENT:Setowning_ent(ent)
	self.DRP_OwningEnt = ent
end