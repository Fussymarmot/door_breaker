--[[
    DOOR BREAKER — настройка клавиши через Q-меню
]]

CreateClientConVar("door_breaker_key", tostring(KEY_G), true, false, "Клавиша для взлома дверей (Door Breaker)")

local wasDown = false

-- Следит за нажатием назначенной клавиши и запускает нужную команду.
hook.Add("Think", "DoorBreaker_KeyTrigger", function()
    local key = GetConVar("door_breaker_key"):GetInt()
    if key <= 0 then
        wasDown = false
        return
    end

    if gui.IsConsoleVisible() then
        wasDown = false
        return
    end

    -- Если меню открыто и курсор виден, клавиша не должна блокировать его.
    if not IsValid(DoorBreaker.ActiveMenu) and vgui.CursorVisible() then
        wasDown = false
        return
    end

    local down = input.IsKeyDown(key)

    if down and not wasDown then
        RunConsoleCommand(DoorBreaker.Config.Bind)
    end

    wasDown = down
end)

-- Отправляет серверу глобальные настройки.
-- Значения хранятся в локальной таблице, потому что server convar
-- нельзя напрямую изменять с клиента.
local function GetCurrentServerValue(name, fallback)
    local cvar = GetConVar(name)
    return cvar and cvar:GetFloat() or fallback
end

local function SendSkinSettings(values)
    net.Start("DoorBreaker_UpdateSkinSettings")
        net.WriteFloat(math.Clamp(values.chance, 0, 100))

        for _, skinId in ipairs(DoorBreaker.Config.RandomSkin.pool or {}) do
            net.WriteFloat(math.Clamp(values.weights[skinId] or 0, 0, 100))
        end
    net.SendToServer()
end

local function AddPercentSlider(panel, title, value, onChanged, tooltip)
    local slider = vgui.Create("DNumSlider", panel)
    slider:SetText(title)
    slider:SetMin(0)
    slider:SetMax(100)
    slider:SetDecimals(0)
    slider:SetValue(value)
    slider:SetTooltip(tooltip or "")
    slider.OnValueChanged = function(self, val)
        onChanged(self, math.Clamp(val, 0, 100))
    end
    panel:AddItem(slider)
    return slider
end

-- Добавляет настройки в панель Utilities.
hook.Add("PopulateToolMenu", "DoorBreaker_SettingsTab", function()
    spawnmenu.AddToolMenuOption("Utilities", "Door System", "DoorBreakerSettings", "Настройки", "", "", function(panel)
        panel:ClearControls()

        panel:Help("Клавиша для взлома дверей (Day R style):")

        local binder = vgui.Create("DBinder", panel)
        binder:SetSize(200, 24)
        binder:SetValue(GetConVar("door_breaker_key"):GetInt())

        binder.OnChange = function(self, num)
            RunConsoleCommand("door_breaker_key", tostring(num))
        end

        panel:AddItem(binder)
        panel:Help("Нажми на поле выше, затем нужную клавишу — она сразу назначится.")

        local rs = DoorBreaker.Config.RandomSkin
        local values = {
            chance = GetCurrentServerValue(
                "door_breaker_skin_chance",
                rs.chance or 0
            ) * 100,
            weights = {},
        }

        for _, skinId in ipairs(rs.pool or {}) do
            values.weights[skinId] = GetCurrentServerValue(
                "door_breaker_skin_weight_" .. skinId,
                (rs.weights and rs.weights[skinId]) or 0
            )
        end

        panel:Help("Вероятность появления кастомной двери")

        AddPercentSlider(
            panel,
            "Кастомная дверь",
            values.chance,
            function(_, val)
                values.chance = val
                SendSkinSettings(values)
            end,
            "Шанс первого броска: станет ли дверь кастомной вообще."
        )

        panel:Help("Если кастомная дверь выпала, выбирается один из скинов ниже по весам.")

        for _, skinId in ipairs(rs.pool or {}) do
            local name = (rs.names and rs.names[skinId]) or ("Скин " .. skinId)

            AddPercentSlider(
                panel,
                name,
                values.weights[skinId],
                function(_, val)
                    values.weights[skinId] = val
                    SendSkinSettings(values)
                end,
                "Вес этого типа среди выпавших кастомных дверей. Веса нормализуются автоматически."
            )
        end

        panel:Help("Пример: кастомные двери 20%, железная 70%, деревянная 30%.")
        panel:ControlHelp("Тогда железная будет выпадать с вероятностью 14% от всех дверей.")
        panel:ControlHelp("Сумма весов может быть любой — 70 + 30, например, автоматически станет 70% / 30%.")

        local refresh = panel:Button("Применить настройки сейчас")
        refresh.DoClick = function()
            SendSkinSettings(values)
        end
    end)
end)
