--[[
    DOOR BREAKER — настройка клавиши через Q-меню
    -----------------------------------------------------------
    Заменяет ручной bind в консоли на удобный DBinder в спавнменю.
    Так как движок блокирует выполнение команды "bind" из аддонов,
    клавиша отслеживается вручную через Think и дёргает ту же самую
    консольную команду, что раньше вызывалась через bind.
]]

CreateClientConVar("door_breaker_key", tostring(KEY_G), true, false, "Клавиша для взлома дверей (Door Breaker)")

local wasDown = false

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

    -- если открыто именно наше меню — не блокируем по курсору,
    -- иначе повторное нажатие не сможет его закрыть
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

hook.Add("PopulateToolMenu", "DoorBreaker_SettingsTab", function()
    spawnmenu.AddToolMenuOption("Utilities", "Door System", "DoorBreakerSettings", "Настройки", "", "", function(panel)
        panel:ClearControls()

        panel:Help("Клавиша для взлома дверей (Day R style):")

        local binder = vgui.Create("DBinder", panel)
        binder:SetSize(200, 24)
        binder:SetValue(GetConVar("door_breaker_key"):GetInt())

        -- у DBinder нет SetConVar (это метод только у DCheckBoxLabel/DNumSlider и т.п.),
        -- поэтому конвар обновляем вручную через OnChange
        binder.OnChange = function(self, num)
            RunConsoleCommand("door_breaker_key", tostring(num))
        end

        panel:AddItem(binder)

        panel:Help("Нажми на поле выше, затем нужную клавишу — она сразу назначится.")

        panel:NumSlider("Шанс кастомной двери", "door_breaker_skin_chance", 0, 1, 2)
        panel:ControlHelp("0 = кастомных дверей не будет никогда, 1 = будут все двери на карте.")
    end)
end)