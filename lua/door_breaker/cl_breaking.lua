--[[
    DOOR BREAKER — клиентская логика взлома (бинд, прогресс-бар, ощущения от ударов)
]]

DoorBreaker.Breaking      = false
DoorBreaker.BreakProgress = 0
DoorBreaker.BreakToolId   = nil
DoorBreaker.LastHitTime   = 0

DoorBreaker.SwingUntil    = 0
DoorBreaker.SwingDuration = 0

-- консольная команда, которую игрок биндит себе на клавишу:
--   bind "g" "door_breaker_use"
concommand.Add(DoorBreaker.Config.Bind, function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    -- уже открыто меню или уже идёт взлом — игнорируем повторное нажатие
    if IsValid(DoorBreaker.ActiveMenu) then return end
    if DoorBreaker.Breaking then return end

    local tr = util.TraceLine({
        start  = ply:EyePos(),
        endpos = ply:EyePos() + ply:EyeAngles():Forward() * DoorBreaker.Config.MaxUseDistance,
        filter = ply,
    })

    if not tr.Hit or not IsValid(tr.Entity) then return end
    if not DoorBreaker.IsBreakable(tr.Entity, ply) then return end

    local panel = vgui.Create("DoorBreakerMenu")
    panel:SetDoor(tr.Entity)
    DoorBreaker.ActiveMenu = panel
end)

function DoorBreaker.RequestBreak(door, toolId)
    if not IsValid(door) then return end
    net.Start("DoorBreaker_Start")
        net.WriteEntity(door)
        net.WriteString(toolId)
    net.SendToServer()
end

net.Receive("DoorBreaker_Progress", function()
    DoorBreaker.Breaking      = true
    DoorBreaker.BreakProgress = net.ReadFloat()
    DoorBreaker.BreakToolId   = net.ReadString()
end)

net.Receive("DoorBreaker_Stop", function()
    DoorBreaker.Breaking      = false
    DoorBreaker.BreakProgress = 0
    DoorBreaker.BreakToolId   = nil
end)

net.Receive("DoorBreaker_Hit", function()
    local attacker = net.ReadEntity()
    local toolId    = net.ReadString()
    local tool      = DoorBreaker.GetTool(toolId)

    print("DoorBreaker_Hit получен")
    print("tool:", tool, "weaponSwingAnim:", tool and tool.weaponSwingAnim)

    if not IsValid(attacker) then return end

    if attacker == LocalPlayer() then
        DoorBreaker.LastHitTime = CurTime()
        LocalPlayer():ViewPunch(Angle(math.Rand(-1.4, 1.4), math.Rand(-1.6, 1.6), 0))

        if tool and tool.weaponSwingAnim then
            DoorBreaker.SwingDuration = tool.swingDuration or 0.25
            DoorBreaker.SwingUntil    = CurTime() + DoorBreaker.SwingDuration
        end
    end

    if tool and tool.weaponSwingAnim then
        attacker:DoAttackEvent()
    end
end)

-- автоотмена, если игрок начинает двигаться или прыгать во время взлома
hook.Add("Think", "DoorBreaker_CancelOnMove", function()
    if not DoorBreaker.Breaking then return end
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    if ply:KeyDown(IN_FORWARD) or ply:KeyDown(IN_BACK)
        or ply:KeyDown(IN_MOVELEFT) or ply:KeyDown(IN_MOVERIGHT)
        or ply:KeyDown(IN_JUMP) then
        net.Start("DoorBreaker_Cancel")
        net.SendToServer()
    end
end)

-- прогресс-бар внизу экрана
hook.Add("HUDPaint", "DoorBreaker_ProgressBar", function()
    if not DoorBreaker.Breaking then return end

    local w, h = ScrW(), ScrH()
    local barW, barH = 380, 24
    local x, y = w / 2 - barW / 2, h - 150

    -- лёгкая вспышка в момент "удара"
    local pulse = math.max(0, 1 - (CurTime() - DoorBreaker.LastHitTime) / 0.25)

    draw.RoundedBox(5, x - 3, y - 3, barW + 6, barH + 6, Color(0, 0, 0, 190))
    draw.RoundedBox(5, x, y, barW, barH, Color(35, 32, 28, 230))
    draw.RoundedBox(5, x, y, barW * DoorBreaker.BreakProgress, barH,
        Color(220 + pulse * 30, 170 + pulse * 40, 40, 255))

    local tool = DoorBreaker.GetTool(DoorBreaker.BreakToolId)
    draw.SimpleText(tool and tool.name or "Взлом двери", "DermaDefaultBold",
        w / 2, y - 16, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)

    draw.SimpleText(math.ceil(DoorBreaker.BreakProgress * 100) .. "%", "DermaDefaultBold",
        w / 2, y + barH / 2, color_black, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)

-- ручной мах вьюмоделью — не зависит от анимаций самого оружия,
-- подменяет финальную позицию/угол вьюмодели уже после всей логики SWEP'а
-- три опорные позы маха: исходная -> замах -> удар -> исходная
local SWING_KEYFRAMES = {
    { t = 0.00, ang = Angle(0, 0, 0),     fwd = 0,  right = 0,  up = 0  },
    { t = 0.35, ang = Angle(16, -12, 10), fwd = -4, right = -2, up = -2 }, -- замах назад-вверх
    { t = 0.55, ang = Angle(-34, 6, -12), fwd = 10, right = 3,  up = -6 }, -- удар вперёд-вниз
    { t = 1.00, ang = Angle(0, 0, 0),     fwd = 0,  right = 0,  up = 0  }, -- возврат
}

local function EaseInOutQuad(t)
    if t < 0.5 then return 2 * t * t end
    return 1 - ((-2 * t + 2) ^ 2) / 2
end

local function GetSwingPose(t)
    for i = 1, #SWING_KEYFRAMES - 1 do
        local a, b = SWING_KEYFRAMES[i], SWING_KEYFRAMES[i + 1]
        if t >= a.t and t <= b.t then
            local span = b.t - a.t
            local localT = span > 0 and ((t - a.t) / span) or 0
            localT = EaseInOutQuad(localT)

            return
                LerpAngle(localT, a.ang, b.ang),
                Lerp(localT, a.fwd, b.fwd),
                Lerp(localT, a.right, b.right),
                Lerp(localT, a.up, b.up)
        end
    end
    return Angle(0, 0, 0), 0, 0, 0
end

hook.Add("CalcViewModelView", "DoorBreaker_ManualSwing", function(wep, vm, oldPos, oldAng, pos, ang)
    if CurTime() > DoorBreaker.SwingUntil then return end

    local remaining = DoorBreaker.SwingUntil - CurTime()
    local t = 1 - (remaining / DoorBreaker.SwingDuration)

    local addAng, fwd, right, up = GetSwingPose(t)

    local newAng = ang + addAng
    local newPos = pos + ang:Forward() * fwd + ang:Right() * right + ang:Up() * up

    return newPos, newAng
end)