local queue = {}
local activeMatch = nil

local function notifyPlayer(target, nType, title, message, duration)
    TriggerClientEvent('fightclub:notify', target, {
        type = nType,
        title = title,
        message = message,
        duration = duration or 3000
    })
end

local function isPlayerQueued(source)
    for i = 1, #queue do
        if queue[i] == source then
            return true
        end
    end
    return false
end

local function removeFromQueue(source)
    for i = #queue, 1, -1 do
        if queue[i] == source then
            table.remove(queue, i)
        end
    end
end

local function clearMatchForPlayer(source)
    if activeMatch and (activeMatch.player1 == source or activeMatch.player2 == source) then
        local otherPlayer = activeMatch.player1 == source and activeMatch.player2 or activeMatch.player1

        if otherPlayer then
            FrameworkBridge.AddMoney(otherPlayer, Config.Economy.winnerPayout)

            notifyPlayer(
                otherPlayer,
                'success',
                'Fight Club',
                ('Opponent disconnected. You received $%d'):format(Config.Economy.winnerPayout),
                5000
            )
        end

        TriggerClientEvent('fightclub:matchEnded', -1, {
            winner = otherPlayer,
            loser = source,
            reason = 'disconnect'
        })

        activeMatch = nil
    end
end

local function tryStartMatch()
    if activeMatch then return end
    if #queue < Config.Match.minPlayers then return end

    local player1 = table.remove(queue, 1)
    local player2 = table.remove(queue, 1)

    TriggerClientEvent('fightclub:setQueued', player1, false)
    TriggerClientEvent('fightclub:setQueued', player2, false)

    activeMatch = {
        player1 = player1,
        player2 = player2,
        started = false
    }

    TriggerClientEvent('fightclub:startCountdown', player1, Config.Match.countdown, player2)
    TriggerClientEvent('fightclub:startCountdown', player2, Config.Match.countdown, player1)

    SetTimeout(Config.Match.countdown * 1000, function()
        if not activeMatch then return end

        activeMatch.started = true

        TriggerClientEvent('fightclub:matchStarted', player1, player2)
        TriggerClientEvent('fightclub:matchStarted', player2, player1)

        notifyPlayer(-1, 'info', 'Fight Club', ('Match started: %s vs %s'):format(
            GetPlayerName(player1),
            GetPlayerName(player2)
        ), 4000)
    end)
end

RegisterNetEvent('fightclub:joinQueue', function()
    local src = source
    local entryFee = Config.Economy.entryFee

    if activeMatch and (activeMatch.player1 == src or activeMatch.player2 == src) then
        notifyPlayer(src, 'error', 'Fight Club', 'You are already in an active match.')
        return
    end

    if isPlayerQueued(src) then
        notifyPlayer(src, 'warning', 'Fight Club', 'You are already in the queue.')
        return
    end

    local balance = FrameworkBridge.GetPlayerMoney(src)
    if balance < entryFee then
        notifyPlayer(src, 'error', 'Fight Club', ('Not enough money. You need $%d'):format(entryFee), 5000)
        return
    end

    local paid = FrameworkBridge.RemoveMoney(src, entryFee)
    if not paid then
        notifyPlayer(src, 'error', 'Fight Club', 'Payment failed.')
        return
    end

    table.insert(queue, src)

    TriggerClientEvent('fightclub:setQueued', src, true)

    notifyPlayer(
        src,
        'success',
        'Fight Club',
        ('You paid $%d and joined the fight queue.'):format(entryFee),
        5000
    )

    notifyPlayer(-1, 'info', 'Fight Club', ('%s joined the queue (%d/%d)'):format(
        GetPlayerName(src),
        #queue,
        Config.Match.minPlayers
    ), 4000)

    tryStartMatch()
end)

RegisterNetEvent('fightclub:leaveQueue', function()
    local src = source
    removeFromQueue(src)

    TriggerClientEvent('fightclub:setQueued', src, false)

    notifyPlayer(src, 'warning', 'Fight Club', 'You left the fight queue. Entry fee is not refunded.', 5000)
end)

RegisterNetEvent('fightclub:playerDied', function()
    local src = source

    if not activeMatch or not activeMatch.started then return end
    if src ~= activeMatch.player1 and src ~= activeMatch.player2 then return end

    local winner = (src == activeMatch.player1) and activeMatch.player2 or activeMatch.player1
    local loser = src

    FrameworkBridge.AddMoney(winner, Config.Economy.winnerPayout)

    TriggerClientEvent('fightclub:matchEnded', -1, {
        winner = winner,
        loser = loser,
        reason = 'death'
    })

    notifyPlayer(-1, 'info', 'Fight Club', ('%s won the fight against %s and received $%d'):format(
        GetPlayerName(winner),
        GetPlayerName(loser),
        Config.Economy.winnerPayout
    ), 5000)

    activeMatch = nil
    tryStartMatch()
end)

AddEventHandler('playerDropped', function()
    local src = source
    removeFromQueue(src)
    clearMatchForPlayer(src)
end)

print(('[fivem-fightclub] server script started with framework: %s'):format(FrameworkBridge.GetName()))