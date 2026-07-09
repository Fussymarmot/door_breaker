--[[
    DOOR BREAKER — мини-игра во время взлома
    Показывает фон двери, крестики для дополнительных кликов и итоговую открытую дверь.
]]

local PANEL = {}

-- Инициализирует панель мини-игры и закрепляет её на месте меню.
function PANEL:Init()
    local cfg = DoorBreaker.Config.MinigameMenu
    self:SetSize(cfg.width, cfg.height)
    self:Center()

    local x, y = self:GetPos()
    self:SetPos(x + DoorBreaker.Config.MenuOffsetX, y + DoorBreaker.Config.MenuOffsetY)

    self:MakePopup()
    self:SetKeyboardInputEnabled(false)

    hook.Add("CreateMove", "DoorBreaker_FreezeMinigame", function(cmd)
        cmd:ClearMovement()
        cmd:ClearButtons()
    end)

    self.crosses = {}
    self.nextSpawn = 0
    self.state = "breaking" -- breaking -> open
    self.openUntil = 0

    self.frameMat = Material(cfg.frame, "noclamp smooth")
end

-- Убирает временные хуки при удалении панели.
function PANEL:OnRemove()
    hook.Remove("CreateMove", "DoorBreaker_FreezeMinigame")
    if self.hookName then
        hook.Remove("DoorBreaker_ClientStopped", self.hookName)
    end
end

-- Привязывает панель к двери и подбирает картинки по её скину.
function PANEL:SetDoor(door)
    self.door = door

    local cfg = DoorBreaker.Config.MinigameMenu
    local skin = IsValid(door) and (door:GetSkin() or 0) or 0
    local bgName = cfg.backgroundsBySkin[skin] or cfg.backgroundsBySkin[0] or "locked_door"

    self.bgMat = Material("door_breaker/minigame/" .. bgName .. ".jpg", "noclamp smooth")
    self.openMat = Material("door_breaker/minigame/" .. bgName .. "_open.jpg", "noclamp smooth")

    self.hookName = "DoorBreaker_Minigame_" .. tostring(self)
    hook.Add("DoorBreaker_ClientStopped", self.hookName, function(completed)
        if not IsValid(self) then return end
        self:OnBreakingStopped(completed)
    end)
end

-- Реагирует на завершение или отмену взлома с сервера.
function PANEL:OnBreakingStopped(completed)
    if self.state ~= "breaking" then return end

    if completed then
        self.state = "open"
        self.openUntil = CurTime() + (DoorBreaker.Config.MinigameMenu.openHoldTime or 1.3)
    else
        self:Remove()
    end
end

-- Спавнит крестик в пределах зоны двери.
function PANEL:SpawnCross()
    local cfg = DoorBreaker.Config.MinigameMenu
    local zone = cfg.hitZone

    local w, h = self:GetWide(), self:GetTall()
    local x = math.Rand(zone.x1, zone.x2) * w
    local y = math.Rand(zone.y1, zone.y2) * h

    table.insert(self.crosses, {
        x = x,
        y = y,
        expires = CurTime() + cfg.crossLifetime,
    })
end

-- Обновляет состояние мини-игры и убирает просроченные крестики.
function PANEL:Think()
    if self.state ~= "breaking" then
        if self.state == "open" and CurTime() > self.openUntil then
            self:Remove()
        end
        return
    end

    local cfg = DoorBreaker.Config.MinigameMenu

    if CurTime() > self.nextSpawn then
        self:SpawnCross()
        self.nextSpawn = CurTime() + cfg.crossSpawnEvery
    end

    for i = #self.crosses, 1, -1 do
        if CurTime() > self.crosses[i].expires then
            table.remove(self.crosses, i)
        end
    end
end

-- Клик по кресту снимает дополнительное время взлома на сервере.
function PANEL:OnMousePressed(mcode)
    if mcode ~= MOUSE_LEFT then return end
    if self.state ~= "breaking" then return end

    local cfg = DoorBreaker.Config.MinigameMenu
    local mx, my = self:CursorPos()

    for i = #self.crosses, 1, -1 do
        local c = self.crosses[i]
        if math.abs(mx - c.x) <= cfg.crossSize / 2 and math.abs(my - c.y) <= cfg.crossSize / 2 then
            table.remove(self.crosses, i)

            local doorType = DoorBreaker.GetDoorType(self.door)
            local hitSound = doorType == "iron" and "door_breaker/crowbar_hit.ogg" or "door_breaker/axe_hit.ogg"
            surface.PlaySound(hitSound)

            net.Start("DoorBreaker_MinigameHit")
            net.SendToServer()

            break
        end
    end
end

-- Рисует фон, крестики и рамку панели.
function PANEL:Paint(w, h)
    local mat = (self.state == "open") and self.openMat or self.bgMat
    if mat then
        surface.SetDrawColor(255, 255, 255, 255)
        surface.SetMaterial(mat)
        surface.DrawTexturedRect(0, 0, w, h)
    end

    if self.state == "breaking" then
        local cfg = DoorBreaker.Config.MinigameMenu

        for _, c in ipairs(self.crosses) do
            local size = cfg.crossSize
            local thickness = 4
            surface.SetDrawColor(220, 40, 40, 255)

            for i = -thickness / 2, thickness / 2 do
                surface.DrawLine(c.x - size / 2 + i, c.y + size / 2, c.x + size / 2 + i, c.y - size / 2)
            end

            for i = -thickness / 2, thickness / 2 do
                surface.DrawLine(c.x - size / 2 + i, c.y - size / 2, c.x + size / 2 + i, c.y + size / 2)
            end
        end
    end

    if self.frameMat then
        surface.SetDrawColor(255, 255, 255, 255)
        surface.SetMaterial(self.frameMat)
        surface.DrawTexturedRect(0, 0, w, h)
    end
end

vgui.Register("DoorBreakerMinigame", PANEL, "DPanel")