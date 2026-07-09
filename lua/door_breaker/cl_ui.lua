--[[
    DOOR BREAKER — меню выбора инструмента
]]

local PANEL = {}

-- Инициализирует и позиционирует меню выбора инструмента.
function PANEL:Init()
    self:SetSize(DoorBreaker.Config.MenuWidth, DoorBreaker.Config.MenuHeight)
    self:Center()

    local x, y = self:GetPos()
    self:SetPos(x + DoorBreaker.Config.MenuOffsetX, y + DoorBreaker.Config.MenuOffsetY)

    self:MakePopup()
    self:SetKeyboardInputEnabled(false)

    hook.Add("CreateMove", "DoorBreaker_FreezeMenu", function(cmd)
        cmd:ClearMovement()
        cmd:ClearButtons()
    end)

    self.tools = {}
    self.bgMaterial = Material(DoorBreaker.Config.MenuBackground or "", "noclamp smooth")

    local mgCfg = DoorBreaker.Config.MinigameMenu
    self.frameMat = mgCfg and mgCfg.frame and Material(mgCfg.frame, "noclamp smooth")

    self.btnClose = vgui.Create("DButton", self)
    self.btnClose:SetText("")
    self.btnClose:SetSize(34, 34)
    self.btnClose:SetPos(self:GetWide() - 40, 0)
    self.btnClose.Paint = function(s, w, h)
        local hover = s:IsHovered()
        draw.RoundedBox(6, 0, 0, w, h, hover and Color(120, 40, 40, 230) or Color(60, 30, 30, 220))
        surface.SetDrawColor(230, 220, 210, 255)
        surface.DrawLine(10, 10, w - 10, h - 10)
        surface.DrawLine(w - 10, 10, 10, h - 10)
    end

    self.btnClose.DoClick = function()
        surface.PlaySound("ui/buttonclickrelease.wav")
        self:Remove()
    end
end

-- Убирает временный хук при закрытии меню.
function PANEL:OnRemove()
    hook.Remove("CreateMove", "DoorBreaker_FreezeMenu")
end

-- Рисует фон и рамку меню.
function PANEL:Paint(w, h)
    surface.SetDrawColor(255, 255, 255, 255)
    surface.SetMaterial(self.bgMaterial)
    surface.DrawTexturedRect(0, 0, w, h)

    if DoorBreaker.Config.MenuShowBorder then
        surface.SetDrawColor(110, 95, 65, 255)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
    end

    if self.frameMat then
        surface.SetDrawColor(255, 255, 255, 255)
        surface.SetMaterial(self.frameMat)
        surface.DrawTexturedRect(0, 0, w, h)
    end
end

-- Привязывает меню к конкретной двери.
function PANEL:SetDoor(door)
    self.door = door

    local mgCfg = DoorBreaker.Config.MinigameMenu
    local skin = IsValid(door) and (door:GetSkin() or 0) or 0
    local bgName = mgCfg and (mgCfg.backgroundsBySkin[skin] or mgCfg.backgroundsBySkin[0])

    if bgName then
        self.bgMaterial = Material("door_breaker/minigame/" .. bgName .. ".jpg", "noclamp smooth")
    end

    self:RebuildButtons()
end

-- Положение кнопок внутри панели.
local LAYOUT = {
    { x = 0.50, y = 0.24 }, -- верхний, по центру
    { x = 0.26, y = 0.68 }, -- нижний левый
    { x = 0.74, y = 0.68 }, -- нижний правый
}

-- Пересобирает список доступных инструментов и кнопки.
function PANEL:RebuildButtons()
    for _, b in ipairs(self.tools) do
        if IsValid(b) then
            b:Remove()
        end
    end

    self.tools = {}

    local ply = LocalPlayer()
    local size = 132

    local availableTools = {}
    for _, toolCfg in ipairs(DoorBreaker.Config.Tools) do
        if DoorBreaker.ToolAllowedForDoor(toolCfg, self.door) then
            table.insert(availableTools, toolCfg)
        end
    end

    for i, toolCfg in ipairs(availableTools) do
        local pos = LAYOUT[i] or LAYOUT[#LAYOUT]
        local available = DoorBreaker.CanUseTool(toolCfg, ply)

        local btn = vgui.Create("DButton", self)
        btn:SetText("")
        btn:SetSize(size, size)
        btn:SetPos(self:GetWide() * pos.x - size / 2, self:GetTall() * pos.y - size / 2)

        local matIcon = Material(toolCfg.icon, "noclamp smooth")
        local matBg = Material("door_breaker/lock_method_bg.png", "noclamp smooth")
        local matTime = Material("door_breaker/timer.png", "noclamp smooth")

        btn.Paint = function(s, w, h)
            local alpha = available and 255 or 90

            surface.SetDrawColor(255, 255, 255, alpha)
            surface.SetMaterial(matBg)
            surface.DrawTexturedRect(0, 0, w, h)

            local iconSize = w * 0.46
            surface.SetDrawColor(255, 255, 255, alpha)
            surface.SetMaterial(matIcon)
            surface.DrawTexturedRect(w / 2 - iconSize / 2, h * 0.16, iconSize, iconSize)

            local tIconSize = 16
            local timeTxt = DoorBreaker.FormatTime(DoorBreaker.GetToolTime(toolCfg, self.door))

            surface.SetFont("DermaDefaultBold")
            local realW = select(1, surface.GetTextSize(timeTxt))

            local totalW = tIconSize + 6 + realW
            local startX = w / 2 - totalW / 2
            local rowY = h * 0.74

            surface.SetDrawColor(255, 210, 90, alpha)
            surface.SetMaterial(matTime)
            surface.DrawTexturedRect(startX, rowY, tIconSize, tIconSize)

            draw.SimpleText(
                timeTxt,
                "DermaDefaultBold",
                startX + tIconSize + 6,
                rowY + tIconSize / 2,
                available and Color(255, 220, 90) or Color(170, 170, 170),
                TEXT_ALIGN_LEFT,
                TEXT_ALIGN_CENTER
            )

            if not available then
                draw.SimpleText(
                    "нет инструмента",
                    "DermaDefault",
                    w / 2,
                    h * 0.93,
                    Color(200, 90, 90),
                    TEXT_ALIGN_CENTER,
                    TEXT_ALIGN_CENTER
                )
            end
        end

        btn.DoClick = function()
            if not available then
                surface.PlaySound("buttons/button10.wav")
                return
            end

            surface.PlaySound("ui/buttonclick.wav")
            DoorBreaker.RequestBreak(self.door, toolCfg.id)

            if DoorBreaker.Config.MinigameMenu and DoorBreaker.Config.MinigameMenu.enabled then
                local mg = vgui.Create("DoorBreakerMinigame")
                if IsValid(mg) then
                    mg:SetDoor(self.door)
                end
            end

            self:Remove()
        end

        table.insert(self.tools, btn)
    end
end

vgui.Register("DoorBreakerMenu", PANEL, "DPanel")
