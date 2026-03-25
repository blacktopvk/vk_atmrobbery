local ESX = exports["es_extended"]:getSharedObject()
local cooldowns = {}

ESX.RegisterServerCallback("atm:canRob", function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then
        cb(false)
        return
    end

    if cooldowns[source] and os.time() < cooldowns[source] then
        cb(false)
        return
    end

    local count = exports.ox_inventory:Search(source, 'count', Config.RequiredItem)

    if not count or count <= 0 then
        cb(false)
        return
    end

    cb(true)
end)

RegisterServerEvent("atm:reward", function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if not xPlayer then return end

    cooldowns[src] = os.time() + Config.Cooldown

    local reward = math.random(Config.Reward.min, Config.Reward.max)

    -- giver sorte penge istedet for cash
    exports.ox_inventory:AddItem(src, 'black_money', reward)

    print(("[ATM] %s fik %s$"):format(GetPlayerName(src), reward))
end)

RegisterServerEvent("atm:fail", function()
    local src = source

    for _, playerId in pairs(GetPlayers()) do
        local xPlayer = ESX.GetPlayerFromId(playerId)

        if xPlayer then
            for _, job in pairs(Config.PoliceJobs) do
                if xPlayer.job.name == job then
                    TriggerClientEvent("ox_lib:notify", playerId, {
                        title = 'Dispatch',
                        description = 'ATM røveri igang!',
                        type = 'error'
                    })
                end
            end
        end
    end

    print(("[ATM] %s fejlede robbery"):format(GetPlayerName(src)))
end)