--[[
    DOOR BREAKER — общие утилиты
    Используются как на клиенте, так и на сервере.
]]

DoorBreaker = DoorBreaker or {}

-- Находит конфиг инструмента по его идентификатору.
function DoorBreaker.GetTool(id)
    for _, tool in ipairs(DoorBreaker.Config.Tools) do
        if tool.id == id then
            return tool
        end
    end

    return nil
end

-- Преобразует секунды в строку формата mm:ss.
function DoorBreaker.FormatTime(seconds)
    seconds = math.max(0, math.floor(seconds))
    local minutes = math.floor(seconds / 60)
    local secs = seconds % 60

    return string.format("%d:%02d", minutes, secs)
end

-- Проверяет, что сущность относится к классу дверей.
function DoorBreaker.IsValidDoorClass(ent)
    return IsValid(ent) and DoorBreaker.Config.ValidClasses[ent:GetClass()] == true
end

-- Проверяет, можно ли ломать дверь в текущий момент.
function DoorBreaker.IsBreakable(ent, ply)
    if not DoorBreaker.IsValidDoorClass(ent) then return false end
    if ent.DoorBreaker_Broken then return false end
    if ent.DoorBreaker_InProgress then return false end

    local override = hook.Run("DoorBreaker_CanBreak", ent, ply)
    if override ~= nil then return override end

    return true
end

-- Проверяет, что игрок держит нужное оружие для выбранного инструмента.
function DoorBreaker.CanUseTool(tool, ply)
    if not tool.requiredWeapons then return true end
    if not IsValid(ply) then return false end

    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) then return false end

    return tool.requiredWeapons[wep:GetClass()] == true
end

-- Возвращает тип двери по текущему скину.
function DoorBreaker.GetDoorType(door)
    if not IsValid(door) then return "wood" end

    local skin = door:GetSkin() or 0
    return DoorBreaker.Config.DoorTypes[skin] or "wood"
end

-- Проверяет, подходит ли инструмент для текущего типа двери.
function DoorBreaker.ToolAllowedForDoor(tool, door)
    if not tool.doorTypes then return true end

    return tool.doorTypes[DoorBreaker.GetDoorType(door)] == true
end

-- Возвращает время взлома с учётом типа двери.
function DoorBreaker.GetToolTime(tool, door)
    if tool.timeByDoorType then
        local doorType = DoorBreaker.GetDoorType(door)
        if tool.timeByDoorType[doorType] then
            return tool.timeByDoorType[doorType]
        end
    end

    return tool.time
end