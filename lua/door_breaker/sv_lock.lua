--[[
    DOOR BREAKER — блокировка открытия дверей со спецскином
]]

local lockedDoorMessageCooldown = {}

-- Блокирует обычное использование заблокированной двери.
hook.Add("PlayerUse", "DoorBreaker_BlockLockedDoors", function(ply, ent)
    if not IsValid(ent) then return end
    if not IsValid(ply) then return end
    if not ent.DoorBreaker_Locked then return end
    if ent.DoorBreaker_Broken then return end

    local now = CurTime()
    local key = ply:EntIndex() .. ":" .. ent:EntIndex()

    if not lockedDoorMessageCooldown[key] or now - lockedDoorMessageCooldown[key] >= 0.25 then
        ply:ChatPrint("Дверь заблокирована. Её можно только выломать.")
        lockedDoorMessageCooldown[key] = now
    end

    return false
end)

-- Предотвращает урон по заблокированной двери, чтобы она не открывалась через триггеры.
hook.Add("EntityTakeDamage", "DoorBreaker_BlockDamageOnLockedDoors", function(target, dmginfo)
    if not IsValid(target) then return end
    if not target.DoorBreaker_Locked then return end
    if target.DoorBreaker_Broken then return end

    dmginfo:SetDamage(0)
    return true
end)

-- Блокирует entity-инпуты на заблокированной двери.
hook.Add("AcceptInput", "DoorBreaker_BlockInputsOnLockedDoors", function(ent, input, activator, caller)
    if not IsValid(ent) then return end
    if not ent.DoorBreaker_Locked then return end
    if ent.DoorBreaker_Broken then return end

    return true
end)

-- Поддерживает заблокированную дверь в закрытом состоянии.
hook.Add("Think", "DoorBreaker_HoldLockedDoorsShut", function()
    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) and ent.DoorBreaker_Locked and not ent.DoorBreaker_Broken then
            if not ent.DoorBreaker_ClosedAngle then
                ent.DoorBreaker_ClosedAngle = ent:GetAngles()
                ent.DoorBreaker_ClosedPos = ent:GetPos()
            end

            if ent:GetAngles() ~= ent.DoorBreaker_ClosedAngle then
                ent:SetAngles(ent.DoorBreaker_ClosedAngle)
            end
            if ent:GetPos() ~= ent.DoorBreaker_ClosedPos then
                ent:SetPos(ent.DoorBreaker_ClosedPos)
            end
        end
    end
end)