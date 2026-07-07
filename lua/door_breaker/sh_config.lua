--[[
    DOOR BREAKER — конфиг
    -----------------------------------------------------------
    Всё, что нужно подкрутить под себя — здесь.
]]

DoorBreaker = DoorBreaker or {}

DoorBreaker.Config = {

    -- имя консольной команды, на которую вешается бинд игроком:
    -- в консоли игрок пишет, например:  bind "g" "door_breaker_use"
    Bind = "door_breaker_use",

    -- с какой дистанции можно НАЧАТЬ взлом (юниты)
    MaxUseDistance = 90,

    -- если игрок отойдёт от двери дальше этого — взлом прервётся
    MaxBreakDistance = 130,

    -- путь к фону меню выбора инструмента
    MenuBackground = "door_breaker/menu_bg.png",

    -- размер меню (ширина, высота)
    MenuWidth = 250,
    MenuHeight = 520,

    -- смещение меню от центра экрана (положительное = вправо, положительное = вниз)
    MenuOffsetX = 400,
    MenuOffsetY = 0,

    -- показывать рамку вокруг меню (true/false)
    MenuShowBorder = false,

    -- классы энтити, которые считаются "дверьми" для системы взлома.
    -- сюда же стоит добавить классы, которые использует
    -- Simple Combine Door Opener на ваших картах, если они отличаются.
    ValidClasses = {
        ["func_door"]          = true,
        ["func_door_rotating"] = true,
        ["prop_dynamic"]       = true,
        ["prop_door_rotating"] = true,
    },

    -- через сколько секунд удалять сорванную с петель дверь (0 = никогда)
    RemoveBrokenAfter = 0,

    -- Подмена моделей на кастомные (с доп. скинами сверх стандартных).
    -- Ключ — оригинальная модель (как она стоит на карте),
    -- значение — твоя перекомпилированная модель с новыми скинами.
    -- Все двери с оригинальной моделью (уже стоящие на карте,
    -- заспавненные через lua_run/spawnmenu, и т.д.) автоматически
    -- получат новую модель при появлении на сервере.
    CustomModelReplacements = {
        ["models/props_c17/door01_left.mdl"] = "models/door_breaker/door01_left_custom.mdl",
        -- ["models/props_c17/door01a.mdl"]   = "models/door_breaker/door01a_custom.mdl",
    },
    -- Рандомный скин при заспавне двери (для дверей, которым подменяется
    -- модель через CustomModelReplacements выше).
    -- chance = 0.10 -> 10% дверей получат один из скинов пула,
    -- остальные 90% останутся со скином 0 (обычная дверь).
    RandomSkin = {
        chance = 0.10,
        pool   = {14, 15, 16, 17}, -- номера скинов (door_breaker_skin1..4)
    },

    -- расстояние, в пределах которого две двери считаются "двойными"
    -- (открывающимися парой) и не участвуют в лотерее скина по отдельности
    DoubleDoorDetectRadius = 50,

    -- Тип двери по номеру скина. От этого зависит, каким инструментом
    -- её можно ломать (см. поле doorTypes у инструментов ниже).
    -- ВНИМАНИЕ: сейчас у всех 4 доп. скинов surfaceprop "wood" в vmt,
    -- то есть по текстурам это варианты дерева. Если скины 3 и 4 у вас
    -- визуально металлические — поменяйте им тип на "iron" вручную:
    DoorTypes = {
        [0] = "wood",
        [1] = "wood",
        [2] = "wood",
        [3] = "wood",
        [4] = "wood",
        [5] = "wood",
        [6] = "wood",
        [7] = "iron",
        [8] = "iron",
        [9] = "iron",
        [10] = "iron",
        [11] = "wood",
        [12] = "iron",
        [13] = "wood",
        [14] = "wood",
        [15] = "iron",
        [16] = "wood", 
        [17] = "iron", 
    },

    -- Bodygroup ручки на кастомной модели двери.
    -- Убирается ТОЛЬКО у дверей с одним из скинов ниже (skins) —
    -- обычная дверь (скин 0) ручку сохраняет.
    DoorHandleBodygroup = {
        group = 1, -- handle01
        value = 0, -- empty (без ручки)
        skins = {14, 15, 16, 17}, -- заменить на те скины, у которых нужно убрать ручку
    },

    -- список доступных инструментов взлома.
    -- порядок в массиве = порядок кружков в меню:
    -- [1] -> верхний кружок, [2] -> нижний левый, [3] -> нижний правый
    Tools = {
        {
            id          = "fist",
            name        = "Голые руки",
            icon        = "door_breaker/fist.png",
            time        = 150, -- 2:30
            hitSound    = "door_breaker/fist_hit.mp3",
            hitInterval = 0.6,
            doorTypes = { wood = true },
        },
        {
            id             = "axe",
            name           = "Топор",
            icon           = "door_breaker/axe.png",
            time           = 60,
            requiredWeapons = {
                ["tfa_dayr_axe_rust"] = true, -- замени/добавь реальные классы топоров
                ["tfa_dayr_axe_normal"] = true,
                ["tfa_dayr_axe_handmade"] = true,
                ["tfa_dayr_axe_steeltools"] = true,
                ["tfa_dayr_axe_irontool"] = true,
                ["tfa_dayr_axe_flint"] = true,
                
            },
            hitSound       = "door_breaker/axe_hit.ogg",
            hitInterval    = 0.8,
            weaponSwingAnim = true,
            swingDuration   = 0.38, 
            doorTypes = { wood = true },
        },
        {
            id          = "crowbar",
            name        = "Лом",
            icon        = "door_breaker/crowbar.png",
            time        = 10, -- время по умолчанию (дерево)
            timeByDoorType = {
                iron = 150, -- 2:30 для железной двери
            },
            requiredWeapons = {
                ["weapon_crowbar"] = true, -- стандартный лом, поменять если появится свой
            },
            hitSound    = "door_breaker/crowbar_hit.ogg",
            hitInterval = 0.5,
            weaponSwingAnim = true,
            swingDuration   = 0.24,
            doorTypes = { wood = true, iron = true },
        },
        {
            id          = "hacksaw",
            name        = "Пила",
            icon        = "door_breaker/hacksaw.png",
            time        = 60,
            requiredWeapons = {
                ["weapon_hacksaw"] = true, -- стандартная пила, поменять если появится свой
            },
            hitSound    = "door_breaker/hacksaws.ogg",
            hitInterval = 0.5,
            weaponSwingAnim = true,
            swingDuration   = 0.24,
            doorTypes = { iron = true },
        },
        {
            id          = "grenade",
            name        = "Граната",
            icon        = "door_breaker/grenade.png",
            time        = 1,
            requiredWeapons = {
                ["dayr_handmade_grenade"] = true, -- заменить на реальный класс взрывчатки, если он есть
            },
            hitSound    = "door_breaker/explosion.ogg",
            hitInterval = 0.5,
            weaponSwingAnim = true,
            swingDuration   = 0.24,
            doorTypes = { iron = true },
        },
        

    },
    -- ПАСХАЛКА: если во время взлома игрок нажмёт колесико мыши (СКМ),
    -- сверху него заспавнится дверь и убьёт его.
    EasterEgg = {
        enabled     = true,
        model       = "models/door_breaker/door01_left_custom.mdl",
        spawnHeight = 220, -- насколько высоко над головой спавнится дверь
        cooldown    = 5,   -- секунд между срабатываниями у одного игрока (защита от спама)
    },
}
