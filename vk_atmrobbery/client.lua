local ESX = exports["es_extended"]:getSharedObject()

local robbing = false
local tabletProp = nil


CreateThread(function()
    for _, model in pairs(Config.ATMModels) do
        exports.ox_target:addModel(model, {
            {
                name = 'atm_robbery',
                icon = 'fa-solid fa-mask',
                label = 'Hack ATM',
                distance = 1.5,
                onSelect = function(data)
                    StartRobbery(data.entity)
                end
            }
        })
    end
end)


function StartRobbery(atm)
    if robbing then return end

    ESX.TriggerServerCallback("atm:canRob", function(canRob)
        if not canRob then
            lib.notify({
                title = 'ATM',
                description = 'Du mangler item eller cooldown',
                type = 'error'
            })
            return
        end

        robbing = true

        StartHackingAnim()

        Wait(1500)

        StartGlowMinigame()
    end)
end


function StartHackingAnim()
    local ped = PlayerPedId()

    local dict = "amb@world_human_seat_wall_tablet@female@base"
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(0) end

    TaskPlayAnim(ped, dict, "base", 8.0, -8.0, -1, 49, 0, false, false, false)

    local model = `prop_cs_tablet`
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end

    tabletProp = CreateObject(model, GetEntityCoords(ped), true, true, true)

    AttachEntityToEntity(
        tabletProp,
        ped,
        GetPedBoneIndex(ped, 57005),
        0.17, 0.10, -0.13,
        20.0, 180.0, 180.0,
        true, true, false, true, 1, true
    )
end


function StopHackingAnim()
    local ped = PlayerPedId()

    ClearPedTasks(ped)

    if tabletProp then
        DeleteEntity(tabletProp)
        tabletProp = nil
    end
end


function StartGlowMinigame()
    local levels = {
        {
            type = "path",
            settings = {
                gridSize = 15,
                lives = 3,
                timeLimit = 18000
            }
        },
        {
            type = "spot",
            settings = {
                gridSize = 6,
                required = 6,
                timeLimit = 18000,
                charSet = "alphabet"
            }
        },
        {
            type = "path",
            settings = {
                gridSize = 19,
                lives = 2,
                timeLimit = 16000
            }
        }
    }

    local currentLevel = 1

    local function startNextLevel()
        if currentLevel > #levels then
            
            StopHackingAnim()

            TriggerServerEvent("atm:reward")

            lib.notify({
                title = 'ATM',
                description = 'Hacking fuldført!',
                type = 'success'
            })

            robbing = false
            return
        end

        local level = levels[currentLevel]

        exports["glow_minigames"]:StartMinigame(function(success)

            -- failsafe
            if success == nil then
                success = false
            end

            if success then
                lib.notify({
                    title = 'Hacking',
                    description = 'Level ' .. currentLevel .. ' klaret',
                    type = 'success'
                })

                currentLevel = currentLevel + 1

                SetTimeout(1200, function()
                    startNextLevel()
                end)

            else
                
                StopHackingAnim()

                TriggerServerEvent("atm:fail")

                lib.notify({
                    title = 'ATM',
                    description = 'DU FEJLEDE, POLITI ER ALARMERET!',
                    type = 'error'
                })

                robbing = false
            end

        end, level.type, level.settings)
    end

    startNextLevel()
end