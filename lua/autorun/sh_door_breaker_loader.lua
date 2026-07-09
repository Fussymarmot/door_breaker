--[[
    DOOR BREAKER — загрузчик аддона
    Подключает все файлы из lua/door_breaker/.
]]

DoorBreaker = DoorBreaker or {}

local function IncludeShared(path)
    if SERVER then
        AddCSLuaFile(path)
    end

    include(path)
end

-- Общие файлы нужны как на сервере, так и на клиенте.
IncludeShared("door_breaker/sh_config.lua")
IncludeShared("door_breaker/sh_util.lua")

if SERVER then
    CreateConVar("door_breaker_skin_chance", "0.10", FCVAR_ARCHIVE, "Шанс появления кастомного скина двери (0.0 - 1.0)")

    -- Клиентские файлы отправляются игрокам.
    AddCSLuaFile("door_breaker/cl_ui.lua")
    AddCSLuaFile("door_breaker/cl_breaking.lua")
    AddCSLuaFile("door_breaker/cl_settings.lua")
    AddCSLuaFile("door_breaker/cl_minigame.lua")

    -- Сетевые строки регистрируются один раз на сервере.
    util.AddNetworkString("DoorBreaker_Start")
    util.AddNetworkString("DoorBreaker_Progress")
    util.AddNetworkString("DoorBreaker_Stop")
    util.AddNetworkString("DoorBreaker_Cancel")
    util.AddNetworkString("DoorBreaker_Hit")
    util.AddNetworkString("DoorBreaker_Broken")
    util.AddNetworkString("DoorBreaker_EasterEgg")
    util.AddNetworkString("DoorBreaker_MinigameHit")
    util.AddNetworkString("DoorBreaker_StartResult")

    include("door_breaker/sv_breaking.lua")
    include("door_breaker/sv_model_swap.lua")
    include("door_breaker/sv_lock.lua")
    include("door_breaker/sv_easter_egg.lua")

    -- Ресурсы добавляются в список для скачивания клиентам.
    resource.AddSingleFile("materials/door_breaker/axe.png")
    resource.AddSingleFile("materials/door_breaker/crowbar.png")
    resource.AddSingleFile("materials/door_breaker/fist.png")
    resource.AddSingleFile("materials/door_breaker/lock_method_bg.png")
    resource.AddSingleFile("materials/door_breaker/timer.png")
    resource.AddSingleFile("materials/door_breaker/menu_bg.png")
    resource.AddSingleFile("materials/door_breaker/explosives.png")
    resource.AddSingleFile("materials/door_breaker/hacksaw.png")
    resource.AddSingleFile("materials/door_breaker/f1.png")
    resource.AddSingleFile("materials/door_breaker/grenade.png")

    resource.AddSingleFile("materials/door_breaker/minigame/frame.png")
    resource.AddSingleFile("materials/door_breaker/minigame/locked_door.jpg")
    resource.AddSingleFile("materials/door_breaker/minigame/locked_door_open.jpg")
    resource.AddSingleFile("materials/door_breaker/minigame/wood_door.jpg")
    resource.AddSingleFile("materials/door_breaker/minigame/wood_door_open.jpg")
    resource.AddSingleFile("materials/door_breaker/minigame/iron_door.jpg")
    resource.AddSingleFile("materials/door_breaker/minigame/iron_door_open.jpg")
    resource.AddSingleFile("materials/door_breaker/minigame/steel_door.jpg")
    resource.AddSingleFile("materials/door_breaker/minigame/steel_door_open.jpg")

    resource.AddSingleFile("sound/door_breaker/axe_hit.ogg")
    resource.AddSingleFile("sound/door_breaker/crowbar_hit.ogg")
    resource.AddSingleFile("sound/door_breaker/fist_hit.mp3")
    resource.AddSingleFile("sound/door_breaker/explosion.ogg")
    resource.AddSingleFile("sound/door_breaker/hacksaws.ogg")
else
    include("door_breaker/cl_ui.lua")
    include("door_breaker/cl_breaking.lua")
    include("door_breaker/cl_settings.lua")
    include("door_breaker/cl_minigame.lua")
end