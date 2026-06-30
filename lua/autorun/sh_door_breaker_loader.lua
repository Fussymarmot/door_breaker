--[[
    DOOR BREAKER — загрузчик аддона
    -----------------------------------------------------------
    Лежит в lua/autorun, поэтому подхватывается движком сам
    (и на сервере, и на клиенте — префикс sh_).
    Подключает все файлы из lua/door_breaker/.
]]

DoorBreaker = DoorBreaker or {}

local function IncludeShared(path)
    if SERVER then
        AddCSLuaFile(path)
    end
    include(path)
end

-- ОБЩЕЕ (конфиг + утилиты нужны и серверу, и клиенту)
IncludeShared("door_breaker/sh_config.lua")
IncludeShared("door_breaker/sh_util.lua")

if SERVER then
    -- говорим клиенту скачать клиентские файлы
    AddCSLuaFile("door_breaker/cl_ui.lua")
    AddCSLuaFile("door_breaker/cl_breaking.lua")

    -- сетевые строки — регистрируются один раз на сервере
    util.AddNetworkString("DoorBreaker_Start")
    util.AddNetworkString("DoorBreaker_Progress")
    util.AddNetworkString("DoorBreaker_Stop")
    util.AddNetworkString("DoorBreaker_Cancel")
    util.AddNetworkString("DoorBreaker_Hit")
    util.AddNetworkString("DoorBreaker_Broken")

    include("door_breaker/sv_breaking.lua")

    -- на всякий случай прописываем картинки в ресурсы,
    -- чтобы они гарантированно докачались клиентам
    resource.AddSingleFile("materials/door_breaker/axe.png")
    resource.AddSingleFile("materials/door_breaker/crowbar.png")
    resource.AddSingleFile("materials/door_breaker/fist.png")
    resource.AddSingleFile("materials/door_breaker/lock_method_bg.png")
    resource.AddSingleFile("materials/door_breaker/timer.png")
    resource.AddSingleFile("materials/door_breaker/menu_bg.png")
else
    include("door_breaker/cl_ui.lua")
    include("door_breaker/cl_breaking.lua")
end
