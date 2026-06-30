--[[
    DOOR BREAKER — серверная логика
]]

local function TimerName(ply)
    return "DoorBreaker_" .. ply:SteamID64()
end

function DoorBreaker.CancelBreaking(ply, door)
    if IsValid(ply) then
        local tname = TimerName(ply)
        if timer.Exists(tname) then timer.Remove(tname) end

        ply.DoorBreaker_Active = false
        ply.DoorBreaker_Door   = nil

        net.Start("DoorBreaker_Stop")
        net.Send(ply)
    end

    if IsValid(door) then
        door.DoorBreaker_InProgress = false
    end
end

function DoorBreaker.StartBreaking(ply, door, tool)
    door.DoorBreaker_InProgress = true
    ply.DoorBreaker_Active = true
    ply.DoorBreaker_Door   = door

    local startTime  = CurTime()
    local duration    = tool.time
    local lastHitTime = 0
    local tname        = TimerName(ply)

    timer.Create(tname, 0.1, 0, function()
        -- всё ещё валидно?
        if not IsValid(ply) or not IsValid(door) then
            DoorBreaker.CancelBreaking(ply, door)
            return
        end

        if ply:GetPos():DistToSqr(door:GetPos()) > (DoorBreaker.Config.MaxBreakDistance ^ 2) then
            DoorBreaker.CancelBreaking(ply, door)
            return
        end

        if not ply:Alive() then
            DoorBreaker.CancelBreaking(ply, door)
            return
        end

        if not DoorBreaker.CanUseTool(tool, ply) then
            DoorBreaker.CancelBreaking(ply, door)
            return
        end

        local elapsed  = CurTime() - startTime
        local progress = math.Clamp(elapsed / duration, 0, 1)

        net.Start("DoorBreaker_Progress")
            net.WriteFloat(progress)
            net.WriteString(tool.id)
        net.Send(ply)

        -- звук + виупанч "удара" с заданным интервалом
        if tool.hitInterval and (elapsed - lastHitTime) >= tool.hitInterval then
            lastHitTime = elapsed
            if tool.hitSound then
                door:EmitSound(tool.hitSound, 75, math.random(95, 105))
            end

            net.Start("DoorBreaker_Hit")
                net.WriteEntity(ply)
                net.WriteString(tool.id)
            net.Broadcast()
        end

        if progress >= 1 then
            timer.Remove(tname)
            ply.DoorBreaker_Active = false
            ply.DoorBreaker_Door   = nil
            door.DoorBreaker_InProgress = false

            net.Start("DoorBreaker_Stop")
            net.Send(ply)

            DoorBreaker.BreakDoor(door)
        end
    end)
end

-- собственно "слом" двери: прячем оригинал, спавним физический пропс,
-- который слетает с петель
function DoorBreaker.BreakDoor(door)
    if not IsValid(door) then return end
    if door.DoorBreaker_Broken then return end
    door.DoorBreaker_Broken = true

    local pos, ang = door:GetPos(), door:GetAngles()
    local model    = door:GetModel()
    local skin     = door:GetSkin()

    door:EmitSound("physics/wood/wood_furniture_break2.wav", 80, 100)

    -- оригинальная дверь больше не мешает и не видна
    door:SetSolid(SOLID_NONE)
    door:SetNotSolid(true)
    door:SetNoDraw(true)
    door:SetCollisionGroup(COLLISION_GROUP_WORLD)

    -- физический пропс сорванной двери
    if model and model ~= "" then
        local broken = ents.Create("prop_physics")
        if IsValid(broken) then
            broken:SetModel(model)
            broken:SetPos(pos)
            broken:SetAngles(ang)
            broken:Spawn()
            broken:SetSkin(skin or 0)
            broken:SetCollisionGroup(COLLISION_GROUP_DEBRIS)

            local phys = broken:GetPhysicsObject()
            if IsValid(phys) then
                phys:Wake()
                local dir = ang:Forward()
                phys:ApplyForceCenter(dir * phys:GetMass() * 200)
                phys:AddAngleVelocity(VectorRand() * 80)
            end

            if DoorBreaker.Config.RemoveBrokenAfter and DoorBreaker.Config.RemoveBrokenAfter > 0 then
                timer.Simple(DoorBreaker.Config.RemoveBrokenAfter, function()
                    if IsValid(broken) then broken:Remove() end
                end)
            end
        end
    end

    net.Start("DoorBreaker_Broken")
        net.WriteEntity(door)
    net.Broadcast()
end

net.Receive("DoorBreaker_Start", function(_, ply)
    if not IsValid(ply) then return end
    if ply.DoorBreaker_Active then return end

    local door   = net.ReadEntity()
    local toolId = net.ReadString()
    local tool   = DoorBreaker.GetTool(toolId)

    if not tool then return end
    if not IsValid(door) then return end
    if not DoorBreaker.IsBreakable(door, ply) then return end
    if door.DoorBreaker_InProgress then return end

    if ply:GetPos():DistToSqr(door:GetPos()) > (DoorBreaker.Config.MaxUseDistance ^ 2) then return end

    if not DoorBreaker.CanUseTool(tool, ply) then return end

    DoorBreaker.StartBreaking(ply, door, tool)
end)

net.Receive("DoorBreaker_Cancel", function(_, ply)
    if not IsValid(ply) or not ply.DoorBreaker_Active then return end
    DoorBreaker.CancelBreaking(ply, ply.DoorBreaker_Door)
end)

hook.Add("PlayerDisconnected", "DoorBreaker_CleanupOnDisconnect", function(ply)
    local tname = TimerName(ply)
    if timer.Exists(tname) then timer.Remove(tname) end
    if IsValid(ply.DoorBreaker_Door) then
        ply.DoorBreaker_Door.DoorBreaker_InProgress = false
    end
end)
