--[[
    DOOR BREAKER — подмена моделей дверей на кастомные
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

-- Возвращает случайный скин с учётом весов из Q-меню.
-- Вес не является отдельным шансом: после выпадения кастомной двери
-- все ненулевые веса нормализуются до 100%.
local function GetWeightedSkin()
    local rs = DoorBreaker.Config.RandomSkin
    local totalWeight = 0
    local entries = {}

    for _, skinId in ipairs(rs.pool or {}) do
        local cvar = GetConVar("door_breaker_skin_weight_" .. skinId)
        local weight = cvar and math.max(cvar:GetFloat(), 0) or 0

        if weight > 0 then
            totalWeight = totalWeight + weight
            table.insert(entries, { id = skinId, weight = weight })
        end
    end

    if totalWeight <= 0 then return nil end

    local roll = math.Rand(0, totalWeight)
    local accumulated = 0

    for _, entry in ipairs(entries) do
        accumulated = accumulated + entry.weight
        if roll <= accumulated then
            return entry.id
        end
    end

    return entries[#entries].id
end

-- Применяет случайный скин и, при необходимости, убирает ручку двери.
function ApplyRandomSkin(ent, candidates)
    if not IsValid(ent) then return end
    if IsPartOfDoubleDoor(ent, candidates) then return end

    local rs = DoorBreaker.Config.RandomSkin
    if not rs or not rs.pool or #rs.pool == 0 then return end

    local chanceCvar = GetConVar("door_breaker_skin_chance")
    local chance = chanceCvar and math.Clamp(chanceCvar:GetFloat(), 0, 1) or 0

    -- Первый бросок: станет ли дверь вообще кастомной?
    if math.Rand(0, 1) > chance then return end

    -- Второй бросок: какой именно кастомный скин выпадет?
    local chosenSkin = GetWeightedSkin()
    if not chosenSkin then return end

    ent:SetSkin(chosenSkin)
    ent.DoorBreaker_Locked = true

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

-- Обрабатывает двери, уже стоящие на карте при старте.
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

-- Обрабатывает двери, заспавненные позже.
hook.Add("OnEntityCreated", "DoorBreaker_SwapDoorModels_New", function(ent)
    timer.Simple(0.1, function()
        if not IsValid(ent) then return end
        if not DoorBreaker.Config.ValidClasses[ent:GetClass()] then return end

        local doors = {}
        for _, e in ipairs(ents.FindByClass(ent:GetClass())) do
            if IsValid(e) then
                table.insert(doors, e)
            end
        end

        SwapModel(ent, doors)
    end)
end)

-- Пересчитывает все двери после изменения конвара без перезахода на карту.
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

local applyingSettings = false

local function RerollFromSettings(reason)
    if applyingSettings then return end
    RerollAllDoors(reason)
end

cvars.AddChangeCallback("door_breaker_skin_chance", function(_, oldValue, newValue)
    RerollFromSettings("Шанс кастомной двери изменён (" .. oldValue .. " -> " .. newValue .. ")")
end, "DoorBreaker_RerollOnChanceChange")

for _, skinId in ipairs(DoorBreaker.Config.RandomSkin.pool or {}) do
    cvars.AddChangeCallback("door_breaker_skin_weight_" .. skinId, function(_, oldValue, newValue)
        RerollFromSettings("Вес скина " .. skinId .. " изменён (" .. oldValue .. " -> " .. newValue .. ")")
    end, "DoorBreaker_RerollOnWeightChange_" .. skinId)
end

-- Настройки из Q-меню приходят на сервер, потому что именно сервер
-- определяет, какие двери реально появятся на карте.
net.Receive("DoorBreaker_UpdateSkinSettings", function(_, ply)
    if not IsValid(ply) or not ply:IsAdmin() then return end

    applyingSettings = true

    local chance = math.Clamp(net.ReadFloat(), 0, 100) / 100
    RunConsoleCommand("door_breaker_skin_chance", tostring(chance))

    for _, skinId in ipairs(DoorBreaker.Config.RandomSkin.pool or {}) do
        local weight = math.Clamp(net.ReadFloat(), 0, 100)
        RunConsoleCommand("door_breaker_skin_weight_" .. skinId, tostring(weight))
    end

    applyingSettings = false
    RerollAllDoors("Настройки кастомных дверей изменены администратором")
end)