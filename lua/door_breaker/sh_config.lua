--[[
    DOOR BREAKER — конфиг
    Все настройки доступны в одном месте.
]]

DoorBreaker = DoorBreaker or {}

DoorBreaker.Config = {
    -- Имя консольной команды, на которую игрок вешает bind.
    Bind = "door_breaker_use",

    -- С какой дистанции можно начать взлом.
    MaxUseDistance = 90,

    -- Если игрок отойдёт дальше этого расстояния, взлом прервётся.
    MaxBreakDistance = 130,

    -- Путь к фону меню выбора инструмента.
    MenuBackground = "door_breaker/menu_bg.png",

    -- Размер меню.
    MenuWidth = 400,
    MenuHeight = 405,

    -- Смещение меню от центра экрана.
    MenuOffsetX = 400,
    MenuOffsetY = 0,

    -- Показывать рамку вокруг меню.
    MenuShowBorder = false,

    -- Мини-игра во время взлома.
    MinigameMenu = {
        enabled = true,
        frame = "door_breaker/minigame/frame.png",

        -- Фон в зависимости от скина двери.
        backgroundsBySkin = {
            [0] = "locked_door",
            [14] = "locked_door",
            [15] = "iron_door",
            [16] = "wood_door",
            [17] = "steel_door",
            [18] = "blocked_door",
            [19] = "iron_door2",
            [20] = "steel_door2",
        },

        width = 400,
        height = 405,

        -- Зона спавна крестиков в долях от размера изображения.
        hitZone = { x1 = 0.28, y1 = 0.08, x2 = 0.74, y2 = 0.88 },

        crossSize = 32,
        crossLifetime = 1.4,
        crossSpawnEvery = 0.9,
        timeBonusPerHit = 3,
        openHoldTime = 1.3,
    },

    -- Классы сущностей, которые считаются дверями.
    ValidClasses = {
        ["func_door"] = true,
        ["func_door_rotating"] = true,
        ["prop_dynamic"] = true,
        ["prop_door_rotating"] = true,
    },

    -- Через сколько секунд удалять сорванную дверь.
    RemoveBrokenAfter = 0,

    -- Подмена моделей на кастомные с дополнительными скинами.
    CustomModelReplacements = {
        ["models/props_c17/door01_left.mdl"] = "models/door_breaker/door01_left_custom.mdl",
    },

    -- Случайный скин для дверей с заменённой моделью.
    RandomSkin = {
        chance = 0.10,
        pool = { 14, 15, 16, 17, 18, 19, 20 },
    },

    -- Расстояние, при котором двери считаются двойными.
    DoubleDoorDetectRadius = 50,

    -- Тип двери по номеру скина.
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
        [18] = "wood",
        [19] = "iron",
        [20] = "iron",
    },

    -- Bodygroup ручки на кастомной модели двери.
    DoorHandleBodygroup = {
        group = 1,
        value = 0,
        skins = { 14, 15, 16, 17, 18, 19, 20 },
    },

    -- Список доступных инструментов взлома.
    Tools = {
        {
            id = "fist",
            name = "Голые руки",
            icon = "door_breaker/fist.png",
            time = 150,
            hitSound = "door_breaker/fist_hit.mp3",
            hitInterval = 0.6,
            doorTypes = { wood = true },
        },
        {
            id = "axe",
            name = "Топор",
            icon = "door_breaker/axe.png",
            time = 60,
            requiredWeapons = {
                ["tfa_dayr_axe_rust"] = true,
                ["tfa_dayr_axe_normal"] = true,
                ["tfa_dayr_axe_handmade"] = true,
                ["tfa_dayr_axe_steeltools"] = true,
                ["tfa_dayr_axe_irontool"] = true,
                ["tfa_dayr_axe_flint"] = true,
            },
            hitSound = "door_breaker/axe_hit.ogg",
            hitInterval = 0.8,
            weaponSwingAnim = true,
            swingDuration = 0.38,
            doorTypes = { wood = true },
        },
        {
            id = "crowbar",
            name = "Лом",
            icon = "door_breaker/crowbar.png",
            time = 10,
            timeByDoorType = {
                iron = 150,
            },
            requiredWeapons = {
                ["weapon_crowbar"] = true,
            },
            hitSound = "door_breaker/crowbar_hit.ogg",
            hitInterval = 0.5,
            weaponSwingAnim = true,
            swingDuration = 0.24,
            doorTypes = { wood = true, iron = true },
        },
        {
            id = "hacksaw",
            name = "Пила",
            icon = "door_breaker/hacksaw.png",
            time = 60,
            requiredWeapons = {
                ["weapon_hacksaw"] = true,
            },
            hitSound = "door_breaker/hacksaws.ogg",
            hitInterval = 0.5,
            weaponSwingAnim = true,
            swingDuration = 0.24,
            doorTypes = { iron = true },
        },
        {
            id = "grenade",
            name = "Граната",
            icon = "door_breaker/grenade.png",
            time = 1,
            requiredWeapons = {
                ["dayr_handmade_grenade"] = true,
            },
            hitSound = "door_breaker/explosion.ogg",
            hitInterval = 0.5,
            weaponSwingAnim = true,
            swingDuration = 0.24,
            doorTypes = { iron = true },
        },
    },

    -- Пасхалка: во время взлома можно активировать удар дверью по игроку.
    EasterEgg = {
        enabled = true,
        model = "models/door_breaker/door01_left_custom.mdl",
        spawnHeight = 220,
        cooldown = 5,
    },
}
