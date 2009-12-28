TOOL.Category   = "Wire - Display"
TOOL.Name       = "GPULib Switcher"
TOOL.Command    = nil
TOOL.ConfigName = ""
TOOL.Tab        = "Wire"

if (CLIENT) then
	language.Add("Tool_wire_gpulib_switcher_name", "GPULib Screen Switcher")
	language.Add("Tool_wire_gpulib_switcher_desc", "Spawns a graphics processing unit")
	language.Add("Tool_wire_gpulib_switcher_0", "Primary: Link a GPULib Screen (Console/Digital/Text Screen/GPU/Oscilloscope) to a different prop, Reload: Unlink")
end

local function switchscreen(screen, ent)
	umsg.Start("wire_gpulib_setent")
		umsg.Short(screen:EntIndex())
		umsg.Short(ent:EntIndex())
	umsg.End()
end

if CLIENT then
	usermessage.Hook("wire_gpulib_setent", function(um)
		local screen = Entity(um:ReadShort())
		if not screen:IsValid() then return end
		if not screen.GPU then return end

		local ent = Entity(um:ReadShort())
		if not ent:IsValid() then return end

		screen.GPU.Entity = ent
		screen.GPU.entindex = ent:EntIndex()

		local model = ent:GetModel()
		local monitor = WireGPU_Monitors[model]

		local h = 512*monitor.RS
		local w = h/monitor.RatioX
		local x = -w/2
		local y = -h/2

		local vecs = {
			{ x  , y   },
			{ x  , y+h },
			{ x+w, y   },
			{ x+w, y+h },
		}

		local mins, maxs = screen:OBBMins(), screen:OBBMaxs()

		local function foo(timerid)
			if not screen:IsValid() then
				timer.Remove(timerid)
				return
			end

			local ang = ent:LocalToWorldAngles(monitor.rot)
			local pos = ent:LocalToWorld(monitor.offset)

			screen.ExtraRBoxPoints = screen.ExtraRBoxPoints or {}
			for i,x,y in ipairs_map(vecs, unpack) do
				local p = Vector(x, y, 0)
				p:Rotate(ang)
				p = screen:WorldToLocal(p+pos)

				screen.ExtraRBoxPoints[i+1000] = p
			end

			Wire_UpdateRenderBounds(screen)
		end

		local timerid = "wire_gpulib_updatebounds"..screen:EntIndex()
		timer.Create(timerid, 5, 0, foo, timerid)

		foo()
	end)
end

function TOOL:LeftClick(trace)
	local ent = trace.Entity

	if ent:IsPlayer() then return false end
	if CLIENT then return true end

	if not ent:IsValid() then return false end

	if self:GetStage() == 0 then
		--if not ent.IsGPU then return false end -- needs check for GPULib-ness
		self.screen = ent

		self:SetStage(1)

		return true
	elseif self:GetStage() == 1 then
		switchscreen(self.screen, ent)
		self.screen = nil

		self:SetStage(0)

		return true
	end
end

function TOOL:Reload(trace)
	if self:GetStage() == 0 then
		local ent = trace.Entity

		if ent:IsPlayer() then return false end
		if CLIENT then return true end

		switchscreen(ent, ent)

		return true
	else
		self:SetStage(0)
		return true
	end
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_gpulib_switcher_name", Description = "#Tool_wire_gpulib_switcher_desc" })
end
