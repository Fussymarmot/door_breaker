--[[
    DOOR BREAKER — блокировка открытия дверей со спецскином
    -----------------------------------------------------------
    Двери, которым выпал рандомный скин (ent.DoorBreaker_Locked),
    нельзя открыть обычным Use — только сломать через систему взлома.
]]

local lockedDoorMessageCooldown = {}

hook.Add("PlayerUse", "DoorBreaker_BlockLockedDoors", function(ply, ent)
    if not IsValid(ent) then return end
    if not IsValid(ply) then return end
    if not ent.DoorBreaker_Locked then return end
    if ent.DoorBreaker_Broken then return end -- уже сломана — пусть работает как обычно

    local now = CurTime()
    local key = ply:EntIndex() .. ":" .. ent:EntIndex()

    if not lockedDoorMessageCooldown[key] or now - lockedDoorMessageCooldown[key] >= 0.25 then
        ply:ChatPrint("Дверь заблокирована. Её можно только выломать.")
        lockedDoorMessageCooldown[key] = now
    end

    return false
end)

-- заблокированная дверь не должна получать урон вообще —
-- иначе некоторые системы (в т.ч. открытие дверей) реагируют на
-- любое попадание (удар прикладом/оружием) как на триггер открытия
hook.Add("EntityTakeDamage", "DoorBreaker_BlockDamageOnLockedDoors", function(target, dmginfo)
    if not IsValid(target) then return end
    if not target.DoorBreaker_Locked then return end
    if target.DoorBreaker_Broken then return end -- уже сломана — урон не важен

    dmginfo:SetDamage(0)
    return true -- полностью отменяет применение урона
end)

-- блокируем любые entity-инпуты (Open/Close/Toggle и т.п.) на заблокированной двери
hook.Add("AcceptInput", "DoorBreaker_BlockInputsOnLockedDoors", function(ent, input, activator, caller)
    if not IsValid(ent) then return end
    if not ent.DoorBreaker_Locked then return end
    if ent.DoorBreaker_Broken then return end

    return true -- true = инпут заблокирован, дальше не обрабатывается
end)

hook.Add("Think", "DoorBreaker_HoldLockedDoorsShut", function()
    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) and ent.DoorBreaker_Locked and not ent.DoorBreaker_Broken then
            if not ent.DoorBreaker_ClosedAngle then
                ent.DoorBreaker_ClosedAngle = ent:GetAngles()
                ent.DoorBreaker_ClosedPos   = ent:GetPos()
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