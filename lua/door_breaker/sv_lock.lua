--[[
    DOOR BREAKER — блокировка открытия дверей со спецскином
    -----------------------------------------------------------
    Двери, которым выпал рандомный скин (ent.DoorBreaker_Locked),
    нельзя открыть обычным Use — только сломать через систему взлома.
]]

hook.Add("PlayerUse", "DoorBreaker_BlockLockedDoors", function(ply, ent)
    if not IsValid(ent) then return end
    if not ent.DoorBreaker_Locked then return end
    if ent.DoorBreaker_Broken then return end -- уже сломана — пусть работает как обычно

    ply:ChatPrint("Дверь заблокирована. Её можно только выломать.")
    return false
end)