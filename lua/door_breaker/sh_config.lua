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
        },
        {
            id          = "crowbar",
            name        = "Лом",
            icon        = "door_breaker/crowbar.png",
            time        = 10,
            requiredWeapons = {
                ["weapon_crowbar"] = true, -- стандартный лом, поменять если появится свой
            },
            hitSound    = "door_breaker/crowbar_hit.ogg",
            hitInterval = 0.5,
            weaponSwingAnim = true,
            swingDuration   = 0.24,
        },
    },
}
