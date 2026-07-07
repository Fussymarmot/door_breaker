--[[
    DOOR BREAKER — подмена моделей дверей на кастомные (с доп. скинами)
    -----------------------------------------------------------
    Смотрит DoorBreaker.Config.CustomModelReplacements и меняет
    модель у всех подходящих дверей на кастомную версию с доп. скинами.
    Двойные двери (стоящие вплотную парой) исключаются из лотереи
    случайного скина — участвуют только одиночные двери.
]]

-- Проверяет, не является ли дверь частью двойной пары.
local function IsPartOfDoubleDoor(ent, candidates)
    local radius = DoorBreaker.Config.DoubleDoorDetectRadius or 100
    for _, other in ipairs(candidates) do
        if other ~= ent and IsValid(other) then
            if ent:GetPos():DistToSqr(other:GetPos()) <= radius * radius then
                return true
            end
        end
    end
    return false
end

-- Применяет случайный скин и при необходимости убирает ручку двери.
function ApplyRandomSkin(ent, candidates)
    if not IsValid(ent) then return end

    -- двойные двери (стоящие вплотную, открывающиеся парой) пропускают лотерею скина
    if IsPartOfDoubleDoor(ent, candidates) then return end

    local rs = DoorBreaker.Config.RandomSkin
    if not rs or not rs.pool or #rs.pool == 0 then return end

    local chance = GetConVar("door_breaker_skin_chance"):GetFloat()
    if math.random() > chance then return end

    local chosenSkin = rs.pool[math.random(#rs.pool)]
    ent:SetSkin(chosenSkin)
    ent.DoorBreaker_Locked = true

    -- ручку убираем только если этот скин есть в списке DoorHandleBodygroup.skins
    local hg = DoorBreaker.Config.DoorHandleBodygroup
    if hg and hg.skins then
        for _, skinId in ipairs(hg.skins) do
            if skinId == chosenSkin then
                ent:SetBodygroup(hg.group, hg.value)
                break
            end
        end
    end
end

-- Подменяет модель двери на кастомную и запускает обработку скина.
function SwapModel(ent, candidates)
    if not IsValid(ent) then return end
    if not DoorBreaker.Config.ValidClasses[ent:GetClass()] then return end

    local model = ent:GetModel()
    if not model or model == "" then return end

    local replacement = DoorBreaker.Config.CustomModelReplacements[model:lower()]
    if replacement then
        ent:SetModel(replacement)

        local phys = ent:GetPhysicsObject()
        if IsValid(phys) then
            phys:EnableMotion(false)
        end
    end

    ApplyRandomSkin(ent, candidates)
end

-- двери, уже стоящие на карте при старте
hook.Add("InitPostEntity", "DoorBreaker_SwapDoorModels_Existing", function()
    timer.Simple(0, function()
        local doors = {}
        for _, ent in ipairs(ents.GetAll()) do
            if IsValid(ent) and DoorBreaker.Config.ValidClasses[ent:GetClass()] then
                table.insert(doors, ent)
            end
        end

        for _, ent in ipairs(doors) do
            SwapModel(ent, doors)
        end
    end)
end)

-- двери, заспавненные позже (spawnmenu, lua_run, другие аддоны и т.д.)
hook.Add("OnEntityCreated", "DoorBreaker_SwapDoorModels_New", function(ent)
    timer.Simple(0.1, function()
        if not IsValid(ent) then return end
        if not DoorBreaker.Config.ValidClasses[ent:GetClass()] then return end

        local doors = {}
        for _, e in ipairs(ents.FindByClass(ent:GetClass())) do
            if IsValid(e) then table.insert(doors, e) end
        end

        SwapModel(ent, doors)
    end)
end)

-- Пересчитывает все двери после изменения конваров без перезахода на карту.
local function RerollAllDoors(reason)
    local doors = {}
    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) and DoorBreaker.Config.ValidClasses[ent:GetClass()] then
            table.insert(doors, ent)
        end
    end

    for _, ent in ipairs(doors) do
        ent.DoorBreaker_Locked = false
        ent:SetSkin(0)
        ApplyRandomSkin(ent, doors)
    end

    print("[Door Breaker] " .. reason .. ", двери пересчитаны: " .. #doors)
end


cvars.AddChangeCallback("door_breaker_skin_chance", function(_, oldValue, newValue)
    RerollAllDoors("Шанс скина изменён (" .. oldValue .. " -> " .. newValue .. ")")
end, "DoorBreaker_RerollOnChanceChange")