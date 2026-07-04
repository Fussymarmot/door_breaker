--[[
    DOOR BREAKER — подмена моделей дверей на кастомные (с доп. скинами)
    -----------------------------------------------------------
    Смотрит DoorBreaker.Config.CustomModelReplacements и меняет
    модель у всех подходящих дверей (и уже стоящих на карте,
    и заспавненных позже) на кастомную версию с доп. скинами.

    SetModel — сетевая функция, клиенты получают новую модель
    автоматически, ничего дополнительно пересылать не нужно.
]]

local function SwapModel(ent)
    if not IsValid(ent) then return end
    if not DoorBreaker.Config.ValidClasses[ent:GetClass()] then return end

    local model = ent:GetModel()
    if not model or model == "" then return end

    local replacement = DoorBreaker.Config.CustomModelReplacements[model:lower()]
    if not replacement then return end

    ent:SetModel(replacement)
end

-- двери, уже стоящие на карте при старте
hook.Add("InitPostEntity", "DoorBreaker_SwapDoorModels_Existing", function()
    timer.Simple(0, function()
        for _, ent in ipairs(ents.GetAll()) do
            SwapModel(ent)
        end
    end)
end)

-- двери, заспавненные позже (spawnmenu, lua_run, другие аддоны и т.д.)
hook.Add("OnEntityCreated", "DoorBreaker_SwapDoorModels_New", function(ent)
    timer.Simple(0, function()
        SwapModel(ent)
    end)
end)
