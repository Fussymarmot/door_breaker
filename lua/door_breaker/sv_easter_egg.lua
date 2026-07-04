--[[
    DOOR BREAKER — пасхалка: дверь на голову
    -----------------------------------------------------------
    Если во время взлома игрок жмёт колесико мыши, ему на голову
    падает дверь и убивает его.
]]

local lastTrigger = {}

net.Receive("DoorBreaker_EasterEgg", function(_, ply)
    if not IsValid(ply) or not ply:Alive() then return end

    local cfg = DoorBreaker.Config.EasterEgg
    if not cfg or not cfg.enabled then return end
    if not ply.DoorBreaker_Active then return end -- только во время реального взлома

    local steamid = ply:SteamID64()
    local now = CurTime()
    if lastTrigger[steamid] and now - lastTrigger[steamid] < cfg.cooldown then return end
    lastTrigger[steamid] = now

    local headPos = ply:GetPos() + Vector(0, 0, cfg.spawnHeight)

    local door = ents.Create("prop_physics")
    if not IsValid(door) then return end

    door:SetModel(cfg.model)
    door:SetPos(headPos)
    door:SetAngles(Angle(0, math.random(0, 360), 90)) -- плашмя, чтобы точно накрыло
    door:Spawn()

    local phys = door:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:SetMass(400)
    end

    -- гарантированное убийство при касании, не полагаясь на физ. урон движка
    door.Touch = function(self, ent)
        if ent == ply and IsValid(ply) and ply:Alive() then
            ply:TakeDamage(1000, self, self)
            ply:ChatPrint("Дверь. Ты. Всё.")
        end
    end

    timer.Simple(8, function()
        if IsValid(door) then door:Remove() end
    end)
end)